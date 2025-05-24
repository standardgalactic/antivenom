import os
from mistralai import Mistral

api_key = os.environ["MISTRAL_API_KEY"]
model = "mistral-large-latest"

client = Mistral(api_key=api_key)

chat_response = client.chat.complete(
    model= model,
    messages = [
        {
            "role": "user",
            "content": "What is the purpose of a null-wavefront in Null Convention Logic?",
        },
    ]
)

model = "mistral-embed"


embeddings_response = client.embeddings.create(
    model=model,
    inputs=[chat_response.choices[0].message.content]
)

print(chat_response.choices[0].message.content)

print(embeddings_response)
