"""Safely generate the Salesforce credential file consumed by Robot suites."""

import json
import os
import shutil
import subprocess
import tempfile
from pathlib import Path
from typing import Any


class CredentialGenerator:
    """Generate org_info.json without exposing credentials to Robot logs."""

    ROBOT_LIBRARY_SCOPE = "GLOBAL"

    def generate_salesforce_org_info(
        self,
        org_alias: str,
        output_path: str = "org_info.json",
        sf_command: str | None = None,
    ) -> str:
        """Create a validated org_info.json and return a non-secret status."""
        alias = str(org_alias).strip()
        if not alias:
            raise ValueError("ORG_ALIAS must not be empty.")

        cli = self._resolve_cli(sf_command)
        org = self._run_json_command(
            cli,
            ["org", "display", "--target-org", alias, "--json"],
            "Salesforce org display",
        )
        self._validate_cli_response(org, "Salesforce org display")

        token_response = self._run_json_command(
            cli,
            [
                "org",
                "auth",
                "show-access-token",
                "--target-org",
                alias,
                "--json",
            ],
            "Salesforce access-token command",
        )
        self._validate_cli_response(
            token_response,
            "Salesforce access-token command",
        )
        access_token = token_response["result"].get("accessToken")
        if not self._is_usable_token(access_token):
            raise RuntimeError(
                "Salesforce CLI did not return a usable access token."
            )

        org_result = org["result"]
        for required_field in ("instanceUrl", "apiVersion"):
            value = org_result.get(required_field)
            if not isinstance(value, str) or not value.strip():
                raise RuntimeError(
                    f"Salesforce org display omitted {required_field}."
                )
        org_result["accessToken"] = access_token

        destination = Path(output_path).resolve()
        destination.parent.mkdir(parents=True, exist_ok=True)
        temporary_path = self._write_temporary_json(destination, org)
        try:
            self._validate_written_file(temporary_path)
            os.replace(temporary_path, destination)
        finally:
            temporary_path.unlink(missing_ok=True)

        return f"Generated a validated org_info.json for alias '{alias}'."

    @staticmethod
    def _resolve_cli(sf_command: str | None) -> str:
        requested = str(sf_command).strip() if sf_command else ""
        if requested:
            resolved = shutil.which(requested)
            if resolved:
                return resolved
            if Path(requested).is_file():
                return str(Path(requested).resolve())
            raise RuntimeError(f"Salesforce CLI command was not found: {requested}")

        for candidate in ("sf.cmd", "sf"):
            resolved = shutil.which(candidate)
            if resolved:
                return resolved
        raise RuntimeError(
            "Salesforce CLI was not found on PATH. Complete docs/Installation.md."
        )

    @staticmethod
    def _run_json_command(
        cli: str,
        arguments: list[str],
        description: str,
    ) -> dict[str, Any]:
        try:
            result = subprocess.run(
                [cli, *arguments],
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
                timeout=60,
                check=False,
            )
        except subprocess.TimeoutExpired as exc:
            raise RuntimeError(f"{description} timed out after 60 seconds.") from exc
        except OSError as exc:
            raise RuntimeError(f"{description} could not be started.") from exc

        if result.returncode != 0:
            raise RuntimeError(
                f"{description} failed with exit code {result.returncode}."
            )
        try:
            payload = CredentialGenerator._parse_json_object(result.stdout)
        except (json.JSONDecodeError, TypeError, ValueError) as exc:
            raise RuntimeError(f"{description} returned invalid JSON.") from exc
        return payload

    @staticmethod
    def _parse_json_object(raw_output: str) -> dict[str, Any]:
        if not isinstance(raw_output, str):
            raise TypeError("Salesforce CLI output must be text.")
        decoder = json.JSONDecoder()
        for position, character in enumerate(raw_output.lstrip("\ufeff")):
            if character != "{":
                continue
            try:
                payload, _ = decoder.raw_decode(raw_output.lstrip("\ufeff")[position:])
            except json.JSONDecodeError:
                continue
            if isinstance(payload, dict):
                return payload
        raise ValueError("Salesforce CLI output contained no JSON object.")

    @staticmethod
    def _validate_cli_response(payload: dict[str, Any], description: str) -> None:
        if str(payload.get("status")) != "0" or not isinstance(
            payload.get("result"), dict
        ):
            raise RuntimeError(f"{description} did not return a successful result.")

    @staticmethod
    def _is_usable_token(value: Any) -> bool:
        return (
            isinstance(value, str)
            and bool(value.strip())
            and not value.lstrip().startswith("[REDACTED]")
        )

    @staticmethod
    def _write_temporary_json(
        destination: Path,
        payload: dict[str, Any],
    ) -> Path:
        descriptor, temporary_name = tempfile.mkstemp(
            prefix=f".{destination.name}.",
            suffix=".tmp",
            dir=destination.parent,
        )
        temporary_path = Path(temporary_name)
        try:
            with os.fdopen(descriptor, "w", encoding="utf-8") as stream:
                json.dump(payload, stream, ensure_ascii=False, indent=2)
                stream.write("\n")
        except Exception:
            temporary_path.unlink(missing_ok=True)
            raise
        return temporary_path

    def _validate_written_file(self, path: Path) -> None:
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
            token = payload["result"]["accessToken"]
        except (OSError, KeyError, TypeError, json.JSONDecodeError) as exc:
            raise RuntimeError("Generated credential file failed validation.") from exc
        if not self._is_usable_token(token):
            raise RuntimeError("Generated credential file failed validation.")
