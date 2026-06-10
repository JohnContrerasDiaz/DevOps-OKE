import logging
import os

import oci
import uvicorn
from fastapi import FastAPI, HTTPException, Query

logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))
logger = logging.getLogger(__name__)

REGION = os.getenv("OCI_REGION", "us-chicago-1")
COMPARTMENT_ID = os.getenv("OCI_COMPARTMENT_ID")
MODEL_ID = os.getenv("OCI_GENAI_MODEL_ID", "meta.llama-4-maverick-17b-128e-instruct-fp8")
SERVICE_ENDPOINT = os.getenv(
    "OCI_GENAI_ENDPOINT",
    f"https://inference.generativeai.{REGION}.oci.oraclecloud.com",
)

app = FastAPI(
    title="Fedesoft Intelligence - Generative AI Assistant",
    root_path=os.getenv("FASTAPI_ROOT_PATH", "/api"),
)


def create_genai_client():
    """Create an OCI Generative AI client using OKE worker node instance principal."""
    if not COMPARTMENT_ID:
        raise RuntimeError("OCI_COMPARTMENT_ID is required")

    signer = oci.auth.signers.InstancePrincipalsSecurityTokenSigner()
    return oci.generative_ai_inference.GenerativeAiInferenceClient(
        config={"region": REGION},
        signer=signer,
        service_endpoint=SERVICE_ENDPOINT,
    )


try:
    gen_ai_client = create_genai_client()
    logger.info("OCI Generative AI client initialized with instance principal in %s", REGION)
except Exception as exc:
    logger.error("Error initializing OCI client with instance principal: %s", exc)
    gen_ai_client = None


@app.get("/health")
def health_check():
    return {
        "status": "healthy",
        "region": REGION,
        "auth_mode": "instance_principal",
        "oci_connected": gen_ai_client is not None,
    }


@app.post("/ask")
async def ask_ai(prompt: str = Query(...)):
    if not gen_ai_client:
        raise HTTPException(
            status_code=500,
            detail="OCI client is not configured. Verify instance principal IAM policy and OCI_COMPARTMENT_ID.",
        )

    if not prompt:
        raise HTTPException(status_code=400, detail="Prompt cannot be empty")

    try:
        logger.info("Sending request to OCI Generative AI")

        chat_detail = oci.generative_ai_inference.models.ChatDetails()
        chat_detail.compartment_id = COMPARTMENT_ID
        chat_detail.serving_mode = oci.generative_ai_inference.models.OnDemandServingMode(
            model_id=MODEL_ID
        )

        chat_request = oci.generative_ai_inference.models.GenericChatRequest()
        chat_request.messages = [
            oci.generative_ai_inference.models.Message(
                role="USER",
                content=[oci.generative_ai_inference.models.TextContent(text=prompt)],
            )
        ]
        chat_request.max_tokens = int(os.getenv("OCI_GENAI_MAX_TOKENS", "600"))
        chat_request.temperature = float(os.getenv("OCI_GENAI_TEMPERATURE", "0.7"))
        chat_detail.chat_request = chat_request

        response = gen_ai_client.chat(chat_detail)
        ai_response_text = response.data.chat_response.choices[0].message.content[0].text

        logger.info("OCI Generative AI response received")
        return {"response": ai_response_text}

    except oci.exceptions.ServiceError as exc:
        logger.error("OCI service error: %s", exc)
        return {"response": f"OCI Generative AI error: {exc.message}"}
    except Exception as exc:
        logger.error("Unexpected error: %s", exc)
        return {"response": f"Internal error: {str(exc)}"}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)