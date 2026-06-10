import os

import requests
import streamlit as st

st.set_page_config(
    page_title="Fedesoft AI Assistant",
    page_icon="AI",
    layout="centered",
)

BACKEND_URL = os.getenv("BACKEND_URL", "http://backend-ai-svc:8000").rstrip("/")

col1, col2 = st.columns([1, 4])

with col1:
    st.image("download.png", width=100)

with col2:
    st.title("Fedesoft - AI Assistant")

if "messages" not in st.session_state:
    st.session_state.messages = []

for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.markdown(message["content"])

if prompt := st.chat_input("En que puedo ayudarte hoy?"):
    st.session_state.messages.append({"role": "user", "content": prompt})
    with st.chat_message("user"):
        st.markdown(prompt)

    with st.chat_message("assistant"):
        try:
            response = requests.post(
                f"{BACKEND_URL}/ask",
                params={"prompt": prompt},
                timeout=30,
            )

            if response.status_code == 200:
                result = response.json()
                data = result.get(
                    "response",
                    f"The backend response did not include the response field. Received: {result}",
                )
            else:
                data = f"Backend error: HTTP {response.status_code}. Check backend-ai logs."

        except requests.exceptions.ConnectionError:
            data = f"Connection error: could not reach backend at {BACKEND_URL}."
        except Exception as exc:
            data = f"Unexpected error: {str(exc)}"

        st.markdown(data)

    st.session_state.messages.append({"role": "assistant", "content": data})