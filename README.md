# palmetto

### Palmetto Bug: (n.) A flying cockroach

(Almost working, currently having certificate issues)

This repo deploys CockroachDB on Fly.io.

## Deploying

- Ensure the Fly CLI and Docker are installed
- Clone the repo
  ```
  git clone https://github.com/kahnpoint/palmetto
  ```
- Change the app name in the `fly.toml` file to something unique
- Change `.env.example` to `.env` and fill in the values.
  - `PALMETTO_APP_NAME` should match the app name in `fly.toml`.
  - `PALMETTO_WEBHOOK_URL` is an optional Discord webhook url, and can be tested by running `source .sh/dev/test-webhook.sh`
- Generate Cockroachdb certs (exclude the -r flag to load preexisting certs)
  ```
  source .sh/dev/create-certs.sh -r
  ```
- Deploy the app
  ```
  bash .sh/fly/deploy.sh
  ```
- The first node in the cluster will bootstrap itself. This can take a couple minutes. You can check the status at https://fly.io/apps/$PALMETTO_APP_NAME/monitoring or with
  ```
  flyctl status
  ```
- When it's finished, proxy the ports to your local machine, then visit the console at http://localhost:8080 and log in with username "server" and the password you set in the `.env` file.
  ```
  bash .sh/fly/proxy.sh
  ```
- After the first node is up, you can add more nodes to the cluster. They will automatically join, and nodes in different regions will geopartition the data correctly. You can see all the available regions with `flyctl platform regions`.
  ```
  flyctl scale count 1 --region cdg # France
  flyctl scale count 1 --region nrt # Japan
  ```
- You can find your connection url with the following command. Your app will connect to the closest node in the cluster. To use ssl, you can use the cert files in the `local_certs` directory.
  ```
  bash .sh/dev/postgres-url.sh
  ```
- You now have a globally-distributed infintely-scaleable postgres-compatible database. Have fun!