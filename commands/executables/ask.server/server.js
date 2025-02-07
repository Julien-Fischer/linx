#!/usr/bin/env node

// This file is licensed under the MIT License.
// See the LICENSE file in the project root for more information:
// https://github.com/Julien-Fischer/linx/blob/master/LICENSE
// Contributor: Célia N'Meil <nmeil.celia@gmail.com>

import express from "express";
import { config } from "dotenv";
import { OpenAI } from "openai";

config();

const DEFAULT_PORT = 3000;

const GptConfig = {
  MODEL: "gpt-4o-mini",
  ROLE: "developer",
  STORE_COMPLETION_FOR_30_DAYS: true,
}

const Http = {
  OK:                    200,
  BAD_REQUEST:           400,
  INTERNAL_SERVER_ERROR: 500,
};

const openai = new OpenAI();

const app = express();
app.use(express.json());

app.post("/ask", async (request, response) => {
  const body = request.body;

  log('-'.repeat(40));
  log('Received incoming request:', body);

  const { question } = body;
  log('Question:', question);

  if (!isProvided(question)) {
    err('question is not defined', body);
    return response
        .status(Http.BAD_REQUEST)
        .json({ error: "Please provide a prompt" });
  }

  try {
    log('Sending request...');
    const completion = await openai.chat.completions
        .create(createOptions(question));

    log('Completion received:', completion);
    const gptResponse = completion.choices[0].message.content;
    log('Mapped response:', gptResponse);

    response
        .status(Http.OK)
        .json({answer: `${gptResponse}`});
  } catch (error) {
    err(error);
    response
        .status(Http.INTERNAL_SERVER_ERROR)
        .json({ error: "Err: Request to OpenAI failed." });
  }
});

const port = process.env.PORT || DEFAULT_PORT;
app.listen(port, () => {
  console.log(`Server listening on http://localhost:${port}`);
});


function createOptions(question) {
  const {ROLE, MODEL, STORE_COMPLETION_FOR_30_DAYS} = GptConfig;
  return {
    messages: [{role: ROLE, content: question}],
    model: MODEL,
    store: STORE_COMPLETION_FOR_30_DAYS,
  };
}

function isProvided(question) {
  return !(question == null || question.trim() === '');
}

function log(...message) {
  console.log('[ask.server]', ...message);
}

function err(...message) {
  console.error('[ask.server] Error:', ...message);
}
