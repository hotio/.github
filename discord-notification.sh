#!/bin/bash

ACTION_LINK="https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
TITLE="Build #${GITHUB_RUN_NUMBER} [${GITHUB_REPOSITORY}]"
COMMIT_MESSAGE="$(curl -u "${GITHUB_OWNER}:${GITHUB_TOKEN}" -fsSL "https://api.github.com/repos/${GITHUB_REPOSITORY}/commits/${GITHUB_SHA}" | jq -r .commit.message | head -1)"
COMMIT_LINK="https://github.com/${GITHUB_REPOSITORY}/commit/${GITHUB_SHA}"

if [[ "${STATUS}" == "success" ]]; then
    COLOR="3066993"
else
    COLOR="15158332"
    json='
    {
      "content": "<@&646967411798573078> Build **[#'${GITHUB_RUN_NUMBER}' ['${GITHUB_REPOSITORY}']](<'${ACTION_LINK}'>)** failed!"
    }
    '
    curl -fsSL -X POST -H "Content-Type: application/json" -d "${json}" "${DISCORD_WEBHOOK}"
fi

if [[ -n "${VERSION_FIELD}" ]]; then
    APP_VERSION="${VERSION_FIELD}"
else
    APP_VERSION="---"
fi

if [[ ! -f "screenshot.png" ]]; then
    curl -fsSL https://raw.githubusercontent.com/docker-hotio/.github/master/backdrop.png > screenshot.png
fi

json='
{
  "embeds": [
    {
      "title": "'${TITLE}'",
      "url": "'${ACTION_LINK}'",
      "color": '${COLOR}',
      "fields": [
        {
          "name": "Docker Image",
          "value": "```'${GITHUB_REPOSITORY//docker-/}:${GITHUB_REF//refs\/heads\//}'```"
        },
        {
          "name": "Commit Message",
          "value": "```'${COMMIT_MESSAGE//\"/\\\"}'```"
        },
        {
          "name": "Commit",
          "value": "['${GITHUB_SHA:0:7}']('${COMMIT_LINK}')",
          "inline": true
        },
        {
          "name": "App Version",
          "value": "'${APP_VERSION}'",
          "inline": true
        },
        {
          "name": "Documentation",
          "value": "[hotio.dev](http://hotio.dev/containers/'${GITHUB_REPOSITORY//${GITHUB_OWNER}\/docker-/}')"
        }
      ],
      "footer": {
        "text": "Powered by GitHub Actions"
      },
      "timestamp": "'$(date -u +'%FT%T.%3NZ')'",
      "image": {
        "url": "attachment://screenshot.png"
      }
    }
  ]
}
'

curl -fsSL -H "Content-Type: multipart/form-data" -F "file=@screenshot.png" -F "payload_json=${json}" "${DISCORD_WEBHOOK}"
