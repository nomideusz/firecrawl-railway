# Deploy and Host Firecrawl on Railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/firecrawl-self-hosted?referralCode=sLjDXb&utm_medium=integration&utm_source=button&utm_campaign=firecrawl-self-hosted)

[Firecrawl](https://firecrawl.dev) turns websites into clean, LLM-ready markdown or structured data. Give it a URL and it scrapes one page, crawls a whole site, maps every link, or searches the web and scrapes the results. JavaScript-heavy pages are rendered in a headless browser. This template runs the open-source Firecrawl (AGPL-3.0) on your own Railway project, so there are no credits or per-page fees.

## About Hosting Firecrawl

This template runs Firecrawl's official images at pinned versions, with an API key in front:

| Service | What it does |
|---|---|
| **Firecrawl** | The public endpoint. A small Caddy gateway that checks your API key and passes requests on. |
| **API** | Firecrawl 2.11.538: the API plus its scrape, crawl and extract workers, in one container. |
| **Playwright** | Firecrawl's headless Chromium service for pages that need JavaScript. |
| **Postgres** | Firecrawl's job queue (NuQ), PostgreSQL 17 with pg_cron, on a volume. |
| **Redis** | Crawl state and rate limits, on a volume. |
| **RabbitMQ** | Job notifications between the API and the workers. |

What it adds over the plain Docker Compose setup:

- **An API key.** Self-hosted Firecrawl has no authentication, so anyone who finds the URL could scrape through your server. Here every request needs `Authorization: Bearer <FIRECRAWL_API_KEY>`, the header every Firecrawl SDK, the MCP server and the n8n node already send. Requests without it get a 401.
- **Pinned official images.** The API, Playwright and Postgres images come from Firecrawl's own registry at fixed versions (Playwright and Postgres by digest, as they only publish `latest`), so a redeploy never picks up an untested build.
- **Clean startup order.** The API waits for Postgres, RabbitMQ and Redis before starting its workers. Without that, a worker that starts first crashes the whole container.
- **Memory you can tune.** `NUQ_WORKER_COUNT` sets how many pages are scraped in parallel. Each worker uses about 400 MB, and the default of 3 (upstream runs 5) saves roughly 800 MB.

## Common Use Cases

- Feeding websites and docs into RAG pipelines, AI agents and LLM apps as markdown
- Crawling a site on a schedule from n8n, Make or your own code to track changes
- A private scraping backend for the Firecrawl MCP server in Claude, Cursor or other agents

## Dependencies for Firecrawl Hosting

- PostgreSQL, Redis and RabbitMQ (all included)
- An OpenAI-compatible API key (optional) for extract, JSON and summary formats

### Deployment Dependencies

- [Firecrawl documentation](https://docs.firecrawl.dev)
- [Firecrawl on GitHub](https://github.com/firecrawl/firecrawl)
- [Template source on GitHub](https://github.com/nomideusz/firecrawl-railway)

### Implementation Details

**Your API key and URL.** After deploy, copy `FIRECRAWL_API_KEY` from the **Firecrawl** service's Variables tab, and its public domain from Settings → Networking. Try it:

```sh
curl -X POST https://<your-domain>/v2/scrape \
  -H "Authorization: Bearer <FIRECRAWL_API_KEY>" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://example.com", "formats": ["markdown"]}'
```

**SDKs.** Point any Firecrawl SDK at your domain:

```python
from firecrawl import Firecrawl
fc = Firecrawl(api_key="<FIRECRAWL_API_KEY>", api_url="https://<your-domain>")
print(fc.scrape("https://example.com", formats=["markdown"]).markdown)
```

```js
import Firecrawl from "@mendable/firecrawl-js";
const fc = new Firecrawl({ apiKey: "<FIRECRAWL_API_KEY>", apiUrl: "https://<your-domain>" });
```

**MCP server and n8n.** For the [Firecrawl MCP server](https://docs.firecrawl.dev/mcp-server), set `FIRECRAWL_API_URL=https://<your-domain>` and `FIRECRAWL_API_KEY`. In n8n's Firecrawl credentials, set the base URL to your domain and paste the key.

**What works out of the box.** Scrape (`/v2/scrape`), crawl (`/v2/crawl`), map (`/v2/map`), batch scrape and search (`/v2/search`) work without any extra keys. Extract, the JSON format and summaries need a model: set `OPENAI_API_KEY` (and `OPENAI_BASE_URL` plus `MODEL_NAME` for OpenRouter or another OpenAI-compatible provider) on the **API** service.

**Queue dashboard.** `https://<your-domain>/admin/<BULL_AUTH_KEY>/queues`, with `BULL_AUTH_KEY` from the API service's variables.

**Proxies.** Set `PROXY_SERVER`, `PROXY_USERNAME` and `PROXY_PASSWORD` on the API service. The Playwright service picks them up too.

**Upgrade.** Change the API service's image tag to a newer [Firecrawl release](https://github.com/firecrawl/firecrawl/pkgs/container/firecrawl) (for example `ghcr.io/firecrawl/firecrawl:2.11.540`) and deploy.

**Things to know.**

- This is open-source Firecrawl, not the hosted service. Firecrawl's cloud-only engine (Fire-engine) for heavily protected sites isn't included, so some sites with strong bot protection will fail here. A proxy helps.
- Anyone with the API key can make your server fetch any URL. Keep the key private and rotate it (change `FIRECRAWL_API_KEY` and redeploy the Firecrawl service) if it leaks.
- Long crawls run in the background: `/v2/crawl` returns an ID right away, and you poll `/v2/crawl/<id>` for results.

**Memory.** Measured on Railway at idle: the API about 2.7 GB (with 3 workers), Playwright about 225 MB, and Postgres, Redis, RabbitMQ and the gateway about 370 MB together. Plan for about 3.3 GB in total, so the Hobby plan or above.

## Why Deploy Firecrawl on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying Firecrawl on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
