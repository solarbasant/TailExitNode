# Tailscale Exit Node on Render 

This repository contains the configuration files required to deploy a permanent, persistent **Tailscale Exit Node** on Render’s Free Tier. 

By default, Render's Free Tier containers are ephemeral and wipe their local storage on every restart, which breaks Tailscale's persistent machine identity and creates duplicate nodes. This project solves that limitation by utilizing **Supabase Storage** as an automated state-management backend, saving you from needing a paid Render persistent disk.

---

##  How It Works

1. **State Restoration:** Upon booting, the container checks a private Supabase Storage bucket for an existing `tailscaled.state` file.
2. **Userspace Routing:** The container launches the Tailscale daemon in userspace networking mode (`--tun=userspace-networking`) to bypass Render's root-level network environment restrictions.
3. **Exit Node Broadcast:** The container connects to your Tailnet and advertises itself as an internet exit node.
4. **State Backup:** Once verified and connected, the updated node credentials and cryptographic keys are uploaded back to Supabase.
5. **Render Health Check Pass:** A minimal `netcat` (nc) TCP listener loop mimics a live web server, satisfying Render’s web application deployment check and preventing a crash loop.

---

## 🛠️ Configuration & Environment Variables

You must supply these environment variables in your Render service configuration dashboard under the **Environment** tab:

| Variable | Source | Description |
| :--- | :--- | :--- |
| `PORT` | Render (Manual Entry) | Set explicitly to **`10000`** to force Render's load balancer to match our container's internal web listener. |
| `TAILSCALE_AUTH_KEY` | Tailscale Admin Console | An auth key generated from your Tailscale settings. **Must be Reusable and NOT Ephemeral.** |
| `SUPABASE_URL` | Supabase API Settings | Your Supabase database project URL (e.g., `https://your-project-id.supabase.co`). |
| `SUPABASE_KEY` | Supabase API Settings | Your project's secret **`service_role`** key (required to bypass RLS policies and write to storage). |

---

##  Project Files Included

* **`Dockerfile`**: Builds a lightweight Debian-slim image containing the official Tailscale client binaries and netcat utilities.
* **`start.sh`**: The orchestrator script handling cloud state-syncing, VPN registration, and the connection-closing health check mock server.
* **`render.yml`**: Infrastructure-as-code blueprint file for deploying directly via Render Web Services.

---

##  Step-by-Step Setup Guide

### Step 1: Create your Supabase Storage Bucket
1. Log into your **Supabase Dashboard** and go to **Storage** (left sidebar).
2. Click **New Bucket**, name it exactly `tailscale` (lowercase), and ensure it is toggled to **Private**.
3. Go to **Project Settings** (gear icon) -> **API** and copy your **Project URL** and the **`service_role`** secret key.

### Step 2: Deploy the Repository to Render
1. Create a **New Web Service** on Render and link it to this GitHub repository.
2. Select **Docker** as your runtime environment.
3. Select your preferred **Region** (Choose **Singapore** if you are accessing from Asia to reduce latency/ping, or **Oregon/Ohio** for the US).
4. Add the 4 environment variables listed in the configuration table above.
5. Click **Deploy Web Service**.

### Step 3: Approve the Exit Node Route
1. Watch your Render deployment logs. Once the setup completes, you should see:
   `State backup completed with HTTP status: 200`
2. Open your **Tailscale Admin Console**.
3. Locate your new machine (named `render-vpn-exit`).
4. Click the **Three Dots Menu (`...`)** -> **Edit route settings...**
5. Toggle the checkbox for **Use as exit node** and click **Save**.

---

##  Maintaining 24/7 Uptime (Anti-Spin Down)

Because Render's Free tier automatically puts web services to sleep after 15 minutes of inbound HTTP inactivity, your VPN will spin down if left unattended. Render's load balancer cannot see your underlying Tailscale VPN traffic.

To keep the service alive **24/7 for free**:
1. Sign up for a free account at an external uptime provider like **UptimeRobot** or **cron-job.org**.
2. Configure a standard HTTP(s) monitor pointing to your Render public URL (e.g., `https://your-app-name.onrender.com`).
3. Set the polling interval to check every **5 or 10 minutes**.

This continuously wakes the micro-web server loop inside `start.sh`, keeping your exit node online indefinitely at zero cost.
