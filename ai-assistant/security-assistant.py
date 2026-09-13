#!/usr/bin/env python3
"""
security-assistant.py

An AI-powered security review agent for Satcorporation's "paved road" initiative.
It reviews Terraform and Ansible code, flags security issues in plain
language, and suggests fixes — helping developers "Do It Right" without
needing to be security experts themselves.

This is the human-in-the-loop layer on top of automated scanners
(tfsec, checkov): those tools catch known misconfiguration patterns,
while this agent explains WHY something matters and how it fits the
bigger picture — the kind of context a junior developer actually needs.

Usage:
    python security-assistant.py review path/to/main.tf
    python security-assistant.py review path/to/playbook.yml
    python security-assistant.py ask "How do I add IAM least-privilege to my EC2 role?"

Requires:
    pip install anthropic --break-system-packages
    export ANTHROPIC_API_KEY=your-key-here
"""

import argparse
import os
import sys
from pathlib import Path

try:
    import anthropic
except ImportError:
    print("Missing dependency. Run: pip install anthropic --break-system-packages")
    sys.exit(1)


SYSTEM_PROMPT = """You are the Satcorporation Paved Road Security Assistant — an
internal tool that helps developers write secure Terraform and Ansible
code without needing to be security experts.

Your job:
1. Review the provided code (Terraform or Ansible) for security issues.
2. For EACH issue found, explain:
   - WHAT the problem is (plain language, no jargon dump)
   - WHY it matters (real-world risk, not just "best practice says so")
   - HOW to fix it (concrete code snippet)
3. If the code follows good practice already, say so explicitly —
   don't invent problems that aren't there.
4. Keep tone encouraging and educational, never condescending. The goal
   is to help developers learn, not to make them feel bad about their code.
5. Prioritize issues by real impact: critical (data exposure, public
   access, no encryption) before minor style issues.
6. If you see Terraform, check for: unencrypted storage, public access,
   overly broad IAM policies, missing versioning/logging, hardcoded
   secrets.
7. If you see Ansible, check for: hardcoded credentials, missing
   'become' scoping, unencrypted variable files (vault), tasks running
   with unnecessary root privileges, missing idempotency.

Format your response with clear headers per issue, and end with a short
summary of priority (what to fix first).
"""


def get_client():
    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        print("Error: ANTHROPIC_API_KEY environment variable not set.")
        print("Get a key at https://console.anthropic.com and run:")
        print("  export ANTHROPIC_API_KEY=your-key-here")
        sys.exit(1)
    return anthropic.Anthropic(api_key=api_key)


def review_file(file_path: str):
    """Reads a Terraform or Ansible file and sends it for security review."""
    path = Path(file_path)
    if not path.exists():
        print(f"Error: file not found: {file_path}")
        sys.exit(1)

    code_content = path.read_text()
    file_type = "Terraform" if path.suffix in (".tf",) else "Ansible" if path.suffix in (".yml", ".yaml") else "code"

    client = get_client()

    print(f"Reviewing {file_path} ({file_type})...\n")
    print("=" * 70)

    with client.messages.stream(
        model="claude-sonnet-4-5",
        max_tokens=2000,
        system=SYSTEM_PROMPT,
        messages=[
            {
                "role": "user",
                "content": f"Please review this {file_type} file for security issues:\n\n```\n{code_content}\n```",
            }
        ],
    ) as stream:
        for text in stream.text_stream:
            print(text, end="", flush=True)

    print("\n" + "=" * 70)


def ask_question(question: str):
    """Free-form Q&A for developers who just want a quick answer."""
    client = get_client()

    print(f"Question: {question}\n")
    print("=" * 70)

    with client.messages.stream(
        model="claude-sonnet-4-5",
        max_tokens=1500,
        system=SYSTEM_PROMPT,
        messages=[{"role": "user", "content": question}],
    ) as stream:
        for text in stream.text_stream:
            print(text, end="", flush=True)

    print("\n" + "=" * 70)


def main():
    parser = argparse.ArgumentParser(
        prog="security-assistant",
        description="AI security review assistant for the Satcorporation paved road",
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    review_parser = subparsers.add_parser("review", help="Review a Terraform or Ansible file for security issues")
    review_parser.add_argument("file", help="Path to the .tf or .yml file to review")

    ask_parser = subparsers.add_parser("ask", help="Ask a free-form security question")
    ask_parser.add_argument("question", help="Your question, in quotes")

    args = parser.parse_args()

    if args.command == "review":
        review_file(args.file)
    elif args.command == "ask":
        ask_question(args.question)


if __name__ == "__main__":
    main()
