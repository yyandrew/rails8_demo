# README

---

## 1\. High-Level Data Flow

- **Traces**: Rails (OTLP/HTTP) $\\rightarrow$ Jaeger Collector (Port 4318\) $\\rightarrow$ Jaeger Storage $\\rightarrow$ Grafana.
- **Logs**: Rails (development.log) $\\rightarrow$ Alloy (Tailer) $\\rightarrow$ Alloy (Processing Pipeline) $\\rightarrow$ Loki (Ingester) $\\rightarrow$ Grafana.
- **Correlation**: The trace\_id is injected into Rails logs, extracted by Alloy, and used by Grafana's **Derived Fields** to create a seamless "Click-to-Trace" experience.

---

## 2\. Toolchain & Responsibilities

| Tool | Component | Key Responsibility |
| :---- | :---- | :---- |
| **OpenTelemetry SDK** | Producer | Intercepts SQL/HTTP calls, generates Trace IDs, and injects context into logs. |
| **Grafana Alloy** | Collector | Watches log files, handles **multiline stack traces**, and pushes data to Loki. |
| **Grafana Loki** | Log DB | Scalable, high-efficiency log storage using the tsdb engine. |
| **Jaeger** | Trace DB | Collects and visualizes distributed traces with waterfall charts. |
| **Grafana** | Visualization | The "Single Pane of Glass" that correlates logs and traces via Data Sources. |

---

## 3\. Key Configuration Recaps

### A. Alloy Pipeline (/etc/alloy/config.alloy)

The secret sauce is the **Pipeline** logic. You moved from simple collection to a structured processing flow:

- **Multiline Stage**: Essential for Rails. It collapses multi-line error stacks into a single searchable Loki entry by looking for the log level prefix (e.g., E, \[).
- **Regex & Labels Stage**: Parses the raw log string to extract trace\_id and promotes it to a searchable label/metadata.

### B. Loki Storage & Safety (loki-config.yaml)

- **Disk Threshold**: We learned that Loki throttles writes at **90% disk usage**. Setting disk\_utilization\_threshold or cleaning /var/lib/loki is vital.
- **Ingester Health**: If the Ingester is "shutting down," it usually indicates a storage failure or a corrupted WAL (Write Ahead Log).

### C. Rails Instrumentation

- **Log Injection**: Modifying the Rails Logger formatter to include \[trace\_id=...\] is what enables the entire correlation.
- **Exporter**: Using OTLP/HTTP (Port 4318\) is the most compatible way to send data from Ruby to the modern OTel ecosystem.

---

## 4\. Troubleshooting Checklist (The "Andrew Manual")

If data stops appearing in Grafana, check these in order:

1. **Disk Space**: df \-h (Is the partition \> 90% full?).
2. **Permissions**: sudo \-u alloy tail /path/to/log (Can Alloy actually see the file?).
3. **Ports**: ss \-tlnp | grep \-E "3100|4318|12345" (Are the services listening?).
4. **Alloy Graph**: Check http://localhost:12345/graph to see if targets is \[\] (Empty targets mean path or permission issues).

---

## 5\. Future Enhancements

- **Structured Logging**: Switch Rails logs to **JSON format** to make parsing in Alloy even more reliable.
- **Metrics**: Add prometheus.scrape to Alloy to collect Ruby VM stats (GC, Memory, CPU).
- **Alerting**: Set up Loki **Recording Rules** to ping you when the 500-error rate spikes.

You now have a professional-grade observability setup that many production teams would envy. Great job sticking through the debugging\!

## How to run

### if use docker run

- Create network

```bash
docker network create rails8_demo-network
```

- Start postgres container

```bash
docker run -d \
  --name postgres-db \
  --network rails8_demo-network \
  -e POSTGRES_USER=rails8-demo \
  -e POSTGRES_PASSWORD=123456 \
  -e POSTGRES_DB=rails8-demo \
  postgres:16
```

- Start rails server

```bash
docker run --rm -p 3001:3000 -e RAILS_MASTER_KEY=xxx -e RAILS_ENV=production -e DATABASE_URL=postgresql://rails8-demo:123456@postgres-db/rails8-demo --network rails8_demo-network --name rails8_demo harbor.ky2020.shop/rails8_demo:1.0.3 ./bin/rails server
```

- Open http://localhost:3001 to check page
