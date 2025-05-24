import os
import time
import json
from datetime import datetime
from mistralai import Mistral
from mistralai.models.sdkerror import SDKError

# Setup Mistral client
api_key = os.environ["MISTRAL_API_KEY"]
client = Mistral(api_key=api_key)
model = "codestral-latest"

# Test cases: Add or modify as needed
test_cases = [
    {
        "name": "hanoi_recursive",
        "prompt": "def solve_hanoi(n: int):",
        "suffix": "n = int(input('How many disks? '))\nprint(solve_hanoi(n))",
        "description": "Classic Tower of Hanoi recursion"
    },
    {
        "name": "fibonacci_recursive",
        "prompt": "def fib(n: int):",
        "suffix": "print(fib(10))",
        "description": "Recursive Fibonacci"
    },
    {
        "name": "factorial_recursive",
        "prompt": "def factorial(n: int):",
        "suffix": "print(factorial(5))",
        "description": "Recursive factorial"
    },
    {
        "name": "binary_search",
        "prompt": "def binary_search(arr, target):",
        "suffix": "print(binary_search([1, 3, 5, 7], 5))",
        "description": "Binary search in sorted list"
    },
    {
        "name": "is_prime",
        "prompt": "def is_prime(n):",
        "suffix": "print(is_prime(17))",
        "description": "Primality check"
    },
]

# FIM generation settings
temperature = 0.0
top_p = 1.0

# Retry handler for rate limits
def safe_fim_complete(client, model, prompt, suffix, retries=5):
    for i in range(retries):
        try:
            return client.fim.complete(
                model=model,
                prompt=prompt,
                suffix=suffix,
                temperature=temperature,
                top_p=top_p,
            )
        except SDKError as e:
            if "429" in str(e):
                wait = 2 ** i
                print(f"[Rate Limit] Waiting {wait}s before retrying...")
                time.sleep(wait)
            else:
                raise e
    raise RuntimeError("Too many retries after rate limit.")

# Store results
results = []

# Run all tests
for case in test_cases:
    print(f"→ Generating: {case['name']}")

    response = safe_fim_complete(client, model, case["prompt"], case["suffix"])
    completion = response.choices[0].message.content.strip()

    full_code = f"{case['prompt']}\n{completion}\n{case['suffix']}"

    results.append({
        "name": case["name"],
        "description": case.get("description", ""),
        "full_code": full_code
    })

# Save to timestamped JSON file
timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
outfile = f"codestral_fim_full_{timestamp}.json"

with open(outfile, "w") as f:
    json.dump(results, f, indent=2)

print(f"\n✅ All results saved to: {outfile}")

