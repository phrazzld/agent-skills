#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from typing import Any


def run_gh(args: list[str]) -> str:
    result = subprocess.run(["gh", *args], capture_output=True, text=True)
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip() or "gh command failed")
    return result.stdout


def gh_json(args: list[str]) -> Any:
    return json.loads(run_gh(args))


def repo_parts(repo: str | None) -> tuple[str, str]:
    if repo:
        if "/" not in repo:
            raise ValueError(f"Invalid --repo format: expected 'owner/name', got '{repo}'")
        owner, name = repo.split("/", 1)
        return owner, name
    payload = gh_json(["repo", "view", "--json", "owner,name"])
    return payload["owner"]["login"], payload["name"]


def viewer_login() -> str:
    return gh_json(["api", "user"])["login"]


def rest_pages(path: str) -> list[dict[str, Any]]:
    page = 1
    items: list[dict[str, Any]] = []
    while True:
        separator = "&" if "?" in path else "?"
        payload = gh_json(["api", f"{path}{separator}per_page=100&page={page}"])
        if not payload:
            break
        if not isinstance(payload, list):
            raise TypeError(f"expected list from {path}, got {type(payload).__name__}")
        items.extend(payload)
        if len(payload) < 100:
            break
        page += 1
    return items


def thread_comments(owner: str, repo: str, thread_id: str, initial_nodes: list[dict[str, Any]], after: str | None) -> list[dict[str, Any]]:
    query = """
query($owner:String!, $repo:String!, $threadId:ID!, $after:String) {
  repository(owner:$owner, name:$repo) {
    node(id:$threadId) {
      ... on PullRequestReviewThread {
        comments(first:100, after:$after) {
          pageInfo { hasNextPage endCursor }
          nodes {
            id
            url
            body
            path
            line
            author { login }
          }
        }
      }
    }
  }
}
""".strip()
    comments = list(initial_nodes)
    cursor = after
    while cursor:
        payload = gh_json(
            [
                "api",
                "graphql",
                "-f",
                f"query={query}",
                "-F",
                f"owner={owner}",
                "-F",
                f"repo={repo}",
                "-F",
                f"threadId={thread_id}",
                "-F",
                f"after={cursor}",
            ]
        )["data"]["repository"]["node"]["comments"]
        comments.extend(payload["nodes"])
        cursor = payload["pageInfo"]["endCursor"] if payload["pageInfo"]["hasNextPage"] else None
    return comments



def review_threads(owner: str, repo: str, pr: int) -> list[dict[str, Any]]:
    query = """
query($owner:String!, $repo:String!, $number:Int!, $after:String) {
  repository(owner:$owner, name:$repo) {
    pullRequest(number:$number) {
      reviewThreads(first:100, after:$after) {
        pageInfo { hasNextPage endCursor }
        nodes {
          id
          isResolved
          isOutdated
          comments(first:100) {
            pageInfo { hasNextPage endCursor }
            nodes {
              id
              url
              body
              path
              line
              author { login }
            }
          }
        }
      }
    }
  }
}
""".strip()
    threads: list[dict[str, Any]] = []
    after: str | None = None
    while True:
        args = [
            "api",
            "graphql",
            "-f",
            f"query={query}",
            "-F",
            f"owner={owner}",
            "-F",
            f"repo={repo}",
            "-F",
            f"number={pr}",
        ]
        if after:
            args += ["-F", f"after={after}"]
        payload = gh_json(args)["data"]["repository"]["pullRequest"]["reviewThreads"]
        for thread in payload["nodes"]:
            page_info = thread["comments"]["pageInfo"]
            thread["comments"]["nodes"] = thread_comments(
                owner,
                repo,
                thread["id"],
                thread["comments"]["nodes"],
                page_info["endCursor"] if page_info["hasNextPage"] else None,
            )
            thread["comments"].pop("pageInfo", None)
            threads.append(thread)
        if not payload["pageInfo"]["hasNextPage"]:
            break
        after = payload["pageInfo"]["endCursor"]
    return threads


def checks(owner: str, repo: str, pr: int) -> list[dict[str, Any]]:
    return gh_json(
        [
            "pr",
            "checks",
            str(pr),
            "--repo",
            f"{owner}/{repo}",
            "--json",
            "name,state,link,startedAt,completedAt",
        ]
    )


def top_level_review_comments(pr_comments: list[dict[str, Any]], author: str) -> list[dict[str, Any]]:
    replies_by_parent: dict[int, list[dict[str, Any]]] = {}
    for comment in pr_comments:
        parent = comment.get("in_reply_to_id")
        if parent is not None:
            replies_by_parent.setdefault(parent, []).append(comment)

    top_level: list[dict[str, Any]] = []
    for comment in pr_comments:
        if comment.get("in_reply_to_id") is not None:
            continue
        replies = replies_by_parent.get(comment["id"], [])
        top_level.append(
            {
                "id": comment["id"],
                "author": comment["user"]["login"],
                "path": comment.get("path"),
                "line": comment.get("line"),
                "url": comment.get("html_url"),
                "body": comment.get("body", ""),
                "reply_count": len(replies),
                "author_reply_count": sum(1 for reply in replies if reply["user"]["login"] == author),
                "reply_ids": [reply["id"] for reply in replies],
            }
        )
    return top_level


def bot_issue_comments(issue_comments: list[dict[str, Any]]) -> list[dict[str, Any]]:
    return [
        {
            "id": comment["id"],
            "author": comment["user"]["login"],
            "url": comment.get("html_url"),
            "body": comment.get("body", ""),
        }
        for comment in issue_comments
        if comment["user"].get("type") == "Bot"
    ]


def main() -> int:
    parser = argparse.ArgumentParser(description="Inventory PR review surfaces for reconciliation.")
    parser.add_argument("pr", type=int, help="Pull request number")
    parser.add_argument("--repo", help="owner/repo (defaults to current gh repo)")
    args = parser.parse_args()

    owner, repo = repo_parts(args.repo)
    author = viewer_login()
    pr_comments = rest_pages(f"repos/{owner}/{repo}/pulls/{args.pr}/comments")
    issue_comments = rest_pages(f"repos/{owner}/{repo}/issues/{args.pr}/comments")
    threads = review_threads(owner, repo, args.pr)

    payload = {
        "repo": f"{owner}/{repo}",
        "pr": args.pr,
        "author": author,
        "checks": checks(owner, repo, args.pr),
        "review_threads": {
            "total": len(threads),
            "unresolved_count": sum(1 for thread in threads if not thread["isResolved"]),
            "items": [
                {
                    "id": thread["id"],
                    "is_resolved": thread["isResolved"],
                    "is_outdated": thread["isOutdated"],
                    "comments": [
                        {
                            "id": comment["id"],
                            "author": (comment.get("author") or {}).get("login"),
                            "path": comment.get("path"),
                            "line": comment.get("line"),
                            "url": comment.get("url"),
                            "body": comment.get("body", ""),
                        }
                        for comment in thread["comments"]["nodes"]
                    ],
                }
                for thread in threads
            ],
        },
        "review_comments": {
            "total": len(pr_comments),
            "top_level_total": sum(1 for comment in pr_comments if comment.get("in_reply_to_id") is None),
            "top_level": top_level_review_comments(pr_comments, author),
        },
        "issue_comments": {
            "total": len(issue_comments),
            "bot_total": sum(1 for comment in issue_comments if comment["user"].get("type") == "Bot"),
            "bot": bot_issue_comments(issue_comments),
        },
    }
    json.dump(payload, sys.stdout, indent=2)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
