# Documentation index

Read in this order if you are new to the project:

| Order | Document | What it is for |
|------:|-----------|----------------|
| 1 | [README.md](../README.md) | What the project is, how to spin it up in 5 minutes |
| 2 | [HOW_IT_WORKS.md](HOW_IT_WORKS.md) | Architecture, layers, startup flow, mental map |
| 2b | [DIAGRAMS.md](DIAGRAMS.md) | Mermaid flows (layers, auth, HTTPS, reports, CI…) |
| 3 | [BUSINESS.md](BUSINESS.md) | Product rules: money, soft-delete, transfers |
| 4 | [MODELS.md](MODELS.md) | Tables, columns, relationships, migrations |
| 5 | [API.md](API.md) | Complete catalog of HTTP endpoints |
| 5b | [FRONTEND.md](FRONTEND.md) | FE first day: auth, demo users, dashboard, Postman |
| 6 | [SECURITY.md](SECURITY.md) | Auth, JWT, MFA, OWASP, environment variables |
| 7 | [REPOSITORIES.md](REPOSITORIES.md) | Data access layer |
| 8 | [TESTING.md](TESTING.md) | How and why we test |
| 9 | [ROADMAP.md](ROADMAP.md) | Maturation history (steps 1–11) |

## What question do you have?

| Question | Document |
|----------|-----------|
| How do I start the project? | README → Quick start |
| Why are there so many folders in `app/`? | HOW_IT_WORKS |
| How does a request / an expense flow? | DIAGRAMS |
| Can the balance be edited by hand? | BUSINESS |
| What happens if I do a DELETE? | BUSINESS + API |
| How do I authenticate / become admin? | SECURITY + API (auth) |
| Which URL do I call from the frontend? | FRONTEND + API |
| What does the database look like? | MODELS |
| Where do I write a SELECT? | REPOSITORIES |
| How do I run the tests? | TESTING |
| What was done at each stage? | ROADMAP |
