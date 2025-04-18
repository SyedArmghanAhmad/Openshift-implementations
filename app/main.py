import os
import streamlit as st
from langchain.chains import ConversationChain
from langchain.memory import ConversationBufferMemory
from langchain_groq import ChatGroq
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Initialize the app
st.title("GenAI Chatbot with Groq")
st.write("A high-performance chatbot deployed on OpenShift")

# Initialize LangChain components with Groq
@st.cache_resource
def load_chain():
    llm=ChatGroq(
        temperature=0.7,
        model_name = "gemma2-9b-it",
        groq_api_key=os.getenv("GROQ_API_KEY")
    )
    memory = ConversationBufferMemory()
    chain = ConversationChain(llm=llm, memory=memory)
    return chain


chain = load_chain()


# Initialize chat history
if "messages" not in st.session_state:
    st.session_state.messages = []

# Display chat messages

for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.markdown(message["content"])


# Chat input
if prompt := st.chat_input("Hi how can i help you today 😃?"):
    # Add message user to chat history
    st.session_state.messages.append({"role":"user" , "content":prompt})
    with st.chat_message("user"):
        st.markdown(prompt)

     # Get AI response
    with st.chat_message("assistant"):
        response_placeholder =st.empty()
        full_response = ""

        # Stream the response for better UX
        for chunk in chain.stream(input={"input":prompt}):
            full_response +=chunk["response"]
            response_placeholder.markdown(full_response + "▌")

        response_placeholder.markdown(full_response)

       # Add assistant response to chat history
    st.session_state.messages.append({"role": "assistant", "content": full_response})




