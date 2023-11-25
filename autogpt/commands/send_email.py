"""Commands to Send Email"""

COMMAND_CATEGORY = "send_email"
COMMAND_CATEGORY_TITLE = "Send Email"

import os
import subprocess
from pathlib import Path

from colorama import Fore

from autogpt.agents.agent import Agent
from autogpt.command_decorator import command
from autogpt.config import Config
from autogpt.logs import logger

ALLOWLIST_CONTROL = "allowlist"
DENYLIST_CONTROL = "denylist"


@command(
    "send_email",
    "Creates a Email and Send it",
    {
        "address": {
            "type": "string",
            "description": "A address of Email ",
            "required": True,
        },
        "title": {
            "type": "string",
            "description": "The Title of Email",
            "required": True,
        },
        "content": {
            "type": "string",
            "description": "A content of Email",
            "required": False,
        }
    },
)
def send_email(address: str, title: str, content: str, agent: Agent) -> str:
    """Create Email and Send it

    Args:
        address (str): The Python code to run
        title (str): A name to be given to the Python file
        content (str): A name to be given to the Python file

    Returns:
        str: The Succ or Fail
    """
    logger.typewriter_log("send_email", Fore.GREEN, f"Send_email for seven: {address},{title}, {content}")


