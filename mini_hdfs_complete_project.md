# Mini HDFS Simulation - Complete Project Code

## Project Structure

```
mini-hdfs/
├── namenode.py              # NameNode - metadata manager
├── datanode0.py             # DataNode 0 - storage node A
├── datanode1.py             # DataNode 1 - storage node B
├── client.py                # Client Flask app with dashboard
├── config.json              # Main configuration
├── config_primary.json      # DataNode 0 config
├── config_secondary.json    # DataNode 1 config
├── templates/
│   └── index.html           # Web dashboard frontend
├── storage/                 # (auto-created) Storage directories
│   ├── storage/             # NameNode (for temporary files)
│   └── ... (per datanode)
└── README.md                # Setup and running guide
```

---

## File 1: config.json (Main Configuration)

```json
{
  "ip": "0.0.0.0",
  "namenode_port": 5000,
  "datanode_port": 7000,
  "chunk_size": 2097152,
  "replication_factor": 2,
  "heartbeat_interval": 5,
  "datanode_timeout": 15,
  "debug": true
}
```

---

## File 2: config_primary.json (DataNode 0)

```json
{
  "node_id": "DataNode_0",
  "ip": "0.0.0.0",
  "port": 7000,
  "namenode_ip": "127.0.0.1",
  "namenode_port": 5000,
  "heartbeat_interval": 5,
  "debug": true,
  "push_replica_on_store": true,
  "namenode_timeout": 5.0
}
```

---

## File 3: config_secondary.json (DataNode 1)

```json
{
  "node_id": "DataNode_1",
  "ip": "0.0.0.0",
  "port": 7001,
  "namenode_ip": "127.0.0.1",
  "namenode_port": 5000,
  "heartbeat_interval": 5,
  "verify_interval": 120,
  "debug": true,
  "register_max_retries": 8,
  "register_backoff_base": 1.0,
  "namenode_timeout": 5.0
}
```

---

## File 4: namenode.py (Complete NameNode Implementation)

```python
#!/usr/bin/env python3
"""
NameNode - Central metadata manager and coordinator for Mini HDFS.
Responsibilities:
- File chunking and metadata management
- Chunk replication coordination
- Heartbeat monitoring from DataNodes
- Re-replication of under-replicated chunks
- Health tracking and failure detection
"""

import os
import json
import threading
import time
import hashlib
import logging
from flask import Flask, request, jsonify, render_template
import requests

# ========== SETUP & CONFIGURATION ==========

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
META_PATH = os.path.join(BASE_DIR, "metadata.json")
CONFIG_PATH = os.path.join(BASE_DIR, "config.json")

# Logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s [NameNode] %(levelname)s: %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler(os.path.join(BASE_DIR, "namenode.log"), mode='a')
    ]
)
logger = logging.getLogger(__name__)

# Load configuration
try:
    with open(CONFIG_PATH, "r") as f:
        CONFIG = json.load(f)
except Exception as e:
    logger.warning(f"Could not load config: {e}. Using defaults.")
    CONFIG = {
        "ip": "0.0.0.0",
        "namenode_port": 5000,
        "chunk_size": 2 * 1024 * 1024,
        "replication_factor": 2,
        "heartbeat_interval": 5,
        "debug": True
    }

# Flask app
app = Flask(__name__, template_folder="templates")
metadata_lock = threading.Lock()

# ========== METADATA MANAGEMENT ==========

def load_metadata():
    """Load metadata from persistent storage."""
    if os.path.exists(META_PATH):
        try:
            with open(META_PATH, "r") as f:
                return json.load(f)
        except Exception as e:
            logger.error(f"Failed to load metadata: {e}")
    return {"files": {}, "datanodes": {}}

metadata = load_metadata()

def persist_metadata():
    """Persist metadata to disk."""
    tmp_path = META_PATH + ".tmp"
    try:
        with open(tmp_path, "w") as f:
            json.dump(metadata, f, indent=2)
        os.replace(tmp_path, META_PATH)
    except Exception as e:
        logger.error(f"Failed to persist metadata: {e}")

def get_alive_datanodes(timeout=15):
    """Get all datanodes that have sent heartbeat within timeout seconds."""
    now = time.time()
    alive = {}
    with metadata_lock:
        for node_id, info in metadata.get("datanodes", {}).items():
            last_hb = info.get("last_heartbeat", 0)
            if now - last_hb < timeout:
                alive[node_id] = info
    return alive

def pick_targets_for_chunk(chunk_index):
    """Select datanodes for chunk replication using round-robin."""
    replication = CONFIG.get("replication_factor", 2)
    alive_nodes = list(get_alive_datanodes().keys())
    
    if not alive_nodes:
        logger.warning("No alive datanodes available for chunk placement")
        return []
    
    targets = []
    for r in range(replication):
        idx = (chunk_index + r) % len(alive_nodes)
        targets.append(alive_nodes[idx])
    
    return targets

# ========== ROUTES ==========

@app.route("/", methods=["GET"])
def index():
    """Serve the dashboard homepage."""
    try:
        with metadata_lock:
            meta_copy = {
                "files": metadata.get("files", {}),
                "datanodes": metadata.get("datanodes", {}),
                "chunk_size": CONFIG.get("chunk_size", 0),
                "replication_factor": CONFIG.get("replication_factor", 2),
                "alive_nodes": list(get_alive_datanodes().keys())
            }
        return render_template("index.html", metadata=json.dumps(meta_copy))
    except Exception as e:
        logger.exception(f"Error rendering dashboard: {e}")
        return str(e), 500

@app.route("/register_datanode", methods=["POST"])
def register_datanode():
    """Register a new datanode or update existing."""
    try:
        body = request.get_json()
        node_id = body.get("node_id")
        ip = body.get("ip", "127.0.0.1")
        port = body.get("port", CONFIG.get("datanode_port", 7000))
        
        with metadata_lock:
            metadata["datanodes"][node_id] = {
                "ip": ip,
                "port": port,
                "last_heartbeat": time.time(),
                "status": "alive"
            }
            persist_metadata()
        
        logger.info(f"Registered DataNode: {node_id} at {ip}:{port}")
        return jsonify({"status": "ok", "node_id": node_id})
    except Exception as e:
        logger.exception(f"Registration error: {e}")
        return jsonify({"status": "error", "msg": str(e)}), 500

@app.route("/heartbeat", methods=["POST"])
def heartbeat():
    """Receive heartbeat from datanode."""
    try:
        body = request.get_json()
        node_id = body.get("node_id")
        
        with metadata_lock:
            if node_id in metadata["datanodes"]:
                metadata["datanodes"][node_id]["last_heartbeat"] = time.time()
                metadata["datanodes"][node_id]["status"] = "alive"
            else:
                # Auto-register unknown node
                metadata["datanodes"][node_id] = {
                    "ip": body.get("ip", "127.0.0.1"),
                    "port": body.get("port", CONFIG.get("datanode_port", 7000)),
                    "last_heartbeat": time.time(),
                    "status": "alive"
                }
            persist_metadata()
        
        logger.debug(f"Heartbeat from {node_id}")
        return jsonify({"status": "ok"})
    except Exception as e:
        logger.exception(f"Heartbeat error: {e}")
        return jsonify({"status": "error", "msg": str(e)}), 500

@app.route("/datanode_stored", methods=["POST"])
def datanode_stored():
    """Datanode confirms chunk storage."""
    try:
        body = request.get_json() or {}
        node_id = body.get("node_id")
        chunk_id = body.get("chunk_id")
        
        if not node_id or not chunk_id:
            return jsonify({"status": "error", "msg": "missing fields"}), 400
        
        with metadata_lock:
            # Update heartbeat
            if node_id in metadata["datanodes"]:
                metadata["datanodes"][node_id]["last_heartbeat"] = time.time()
            
            # Update chunk replica location
            for fname, fmeta in metadata.get("files", {}).items():
                if chunk_id in fmeta.get("chunks", {}):
                    if node_id not in fmeta["chunks"][chunk_id]:
                        fmeta["chunks"][chunk_id].append(node_id)
            
            persist_metadata()
        
        logger.debug(f"Chunk {chunk_id} confirmed stored on {node_id}")
        return jsonify({"status": "ok"})
    except Exception as e:
        logger.exception(f"datanode_stored error: {e}")
        return jsonify({"status": "error", "msg": str(e)}), 500

@app.route("/report_corruption", methods=["POST"])
def report_corruption():
    """Handle corruption reports from datanodes."""
    try:
        body = request.get_json() or {}
        node_id = body.get("node_id")
        chunk_id = body.get("chunk_id")
        
        logger.warning(f"Corruption reported from {node_id} for chunk {chunk_id}: {body}")
        
        with metadata_lock:
            # Remove corrupted chunk from node
            for fname, fmeta in metadata.get("files", {}).items():
                if chunk_id in fmeta.get("chunks", {}):
                    fmeta["chunks"][chunk_id] = [
                        n for n in fmeta["chunks"][chunk_id] if n != node_id
                    ]
            persist_metadata()
        
        return jsonify({"status": "ok"})
    except Exception as e:
        logger.exception(f"report_corruption error: {e}")
        return jsonify({"status": "error", "msg": str(e)}), 500

@app.route("/upload", methods=["POST"])
def upload_file():
    """Handle file upload and chunking."""
    try:
        replication = CONFIG.get("replication_factor", 2)
        chunk_size = CONFIG.get("chunk_size", 2 * 1024 * 1024)
        
        file_obj = request.files.get("file")
        if not file_obj:
            return jsonify({"status": "error", "msg": "no file"}), 400
        
        filename = request.form.get("filename") or file_obj.filename
        data = file_obj.read()
        total_size = len(data)
        
        num_chunks = (total_size + chunk_size - 1) // chunk_size
        logger.info(f"Uploading {filename}: {total_size} bytes → {num_chunks} chunks")
        
        # Check alive datanodes
        alive = get_alive_datanodes()
        if len(alive) < replication:
            return jsonify({
                "status": "error",
                "msg": "Not enough alive datanodes",
                "required": replication,
                "available": len(alive)
            }), 400
        
        file_entry = {"chunks": {}, "num_chunks": num_chunks, "size": total_size}
        stored_chunks = 0
        
        # Split and upload chunks
        for i in range(num_chunks):
            start = i * chunk_size
            chunk_data = data[start:start + chunk_size]
            chunk_id = f"{filename}.chunk{i}"
            
            targets = pick_targets_for_chunk(i)
            if not targets:
                return jsonify({"status": "error", "msg": "failed to pick targets"}), 500
            
            stored_on = []
            
            # Try to store on each target
            for node_id in targets:
                with metadata_lock:
                    dn = metadata["datanodes"].get(node_id)
                
                if not dn:
                    continue
                
                url = f"http://{dn['ip']}:{dn['port']}/store_chunk"
                
                for attempt in range(1, 4):
                    try:
                        files = {"chunk": (chunk_id, chunk_data)}
                        resp = requests.post(
                            url,
                            files=files,
                            data={"chunk_id": chunk_id, "filename": filename},
                            timeout=60
                        )
                        
                        if resp.status_code == 200:
                            stored_on.append(node_id)
                            logger.info(f"Stored {chunk_id} on {node_id}")
                            break
                        
                    except Exception as e:
                        logger.warning(f"Attempt {attempt} to store {chunk_id} on {node_id}: {e}")
                        time.sleep(1)
            
            if not stored_on:
                return jsonify({
                    "status": "error",
                    "msg": f"Could not store chunk {i}",
                    "chunk_id": chunk_id
                }), 500
            
            file_entry["chunks"][chunk_id] = stored_on
            stored_chunks += 1
        
        # Store metadata
        with metadata_lock:
            metadata["files"][filename] = file_entry
            persist_metadata()
        
        logger.info(f"Successfully uploaded {filename} in {stored_chunks} chunks")
        return jsonify({
            "status": "ok",
            "filename": filename,
            "num_chunks": num_chunks,
            "size": total_size
        })
    
    except Exception as e:
        logger.exception(f"Upload error: {e}")
        return jsonify({"status": "error", "msg": str(e)}), 500

@app.route("/metadata", methods=["GET"])
def get_metadata():
    """Get system metadata."""
    try:
        with metadata_lock:
            alive_nodes = get_alive_datanodes()
            meta_copy = {
                "files": metadata.get("files", {}),
                "datanodes": metadata.get("datanodes", {}),
                "alive_count": len(alive_nodes),
                "total_count": len(metadata.get("datanodes", {}))
            }
        return jsonify(meta_copy)
    except Exception as e:
        logger.exception(f"get_metadata error: {e}")
        return jsonify({"status": "error", "msg": str(e)}), 500

@app.route("/list_files", methods=["GET"])
def list_files():
    """List all uploaded files."""
    try:
        with metadata_lock:
            files = list(metadata.get("files", {}).keys())
        return jsonify({"files": files})
    except Exception as e:
        logger.exception(f"list_files error: {e}")
        return jsonify({"status": "error", "msg": str(e)}), 500

@app.route("/replicate_chunk", methods=["POST"])
def replicate_chunk():
    """Re-replicate chunk to another node."""
    try:
        body = request.get_json()
        chunk_id = body.get("chunk_id")
        src_node = body.get("src_node")
        dest_node = body.get("dest_node")
        
        with metadata_lock:
            src_dn = metadata["datanodes"].get(src_node)
            dest_dn = metadata["datanodes"].get(dest_node)
        
        if not src_dn or not dest_dn:
            return jsonify({"status": "error", "msg": "unknown datanode"}), 400
        
        # Fetch from source
        resp = requests.get(
            f"http://{src_dn['ip']}:{src_dn['port']}/get_chunk",
            params={"chunk_id": chunk_id},
            timeout=30
        )
        
        if resp.status_code != 200:
            return jsonify({"status": "error", "msg": "fetch failed"}), 500
        
        # Store on destination
        files = {"chunk": (chunk_id, resp.content)}
        resp2 = requests.post(
            f"http://{dest_dn['ip']}:{dest_dn['port']}/store_chunk",
            files=files,
            data={"chunk_id": chunk_id, "is_replica": "true"},
            timeout=60
        )
        
        if resp2.status_code == 200:
            with metadata_lock:
                for fname, fmeta in metadata.get("files", {}).items():
                    if chunk_id in fmeta.get("chunks", {}):
                        if dest_node not in fmeta["chunks"][chunk_id]:
                            fmeta["chunks"][chunk_id].append(dest_node)
                persist_metadata()
            
            logger.info(f"Re-replicated {chunk_id} from {src_node} to {dest_node}")
            return jsonify({"status": "ok"})
        
        return jsonify({"status": "error", "msg": "destination store failed"}), 500
    
    except Exception as e:
        logger.exception(f"replicate_chunk error: {e}")
        return jsonify({"status": "error", "msg": str(e)}), 500

def re_replication_monitor():
    """Background thread to detect and fix under-replication."""
    logger.info("Re-replication monitor started")
    
    while True:
        try:
            time.sleep(10)
            
            with metadata_lock:
                replication = CONFIG.get("replication_factor", 2)
                dnodes = metadata.get("datanodes", {})
                alive_nodes = {
                    nid for nid, info in dnodes.items()
                    if time.time() - info.get("last_heartbeat", 0) < 15
                }
                
                for fname, fmeta in metadata.get("files", {}).items():
                    for chunk_id, hosts in list(fmeta.get("chunks", {}).items()):
                        alive_hosts = [h for h in hosts if h in alive_nodes]
                        
                        if len(alive_hosts) < replication:
                            if not alive_hosts:
                                logger.warning(f"Chunk {chunk_id} has NO alive replicas!")
                                continue
                            
                            src = alive_hosts[0]
                            candidates = [n for n in alive_nodes if n not in hosts]
                            
                            if not candidates:
                                logger.warning(f"No candidates for re-replication of {chunk_id}")
                                continue
                            
                            dest = candidates[0]
                            
                            try:
                                logger.info(f"Re-replicating {chunk_id}: {src} → {dest}")
                                requests.post(
                                    f"http://127.0.0.1:{CONFIG.get('namenode_port', 5000)}/replicate_chunk",
                                    json={
                                        "chunk_id": chunk_id,
                                        "src_node": src,
                                        "dest_node": dest
                                    },
                                    timeout=60
                                )
                            except Exception as e:
                                logger.warning(f"Re-replication error: {e}")
        
        except Exception as e:
            logger.exception(f"Re-replication monitor error: {e}")

# ========== MAIN ==========

if __name__ == "__main__":
    logger.info("=" * 60)
    logger.info("Starting NameNode")
    logger.info("=" * 60)
    
    # Start background monitors
    monitor_thread = threading.Thread(target=re_replication_monitor, daemon=True)
    monitor_thread.start()
    
    # Run Flask
    try:
        app.run(
            host=CONFIG.get("ip", "0.0.0.0"),
            port=CONFIG.get("namenode_port", 5000),
            debug=CONFIG.get("debug", False),
            threaded=True
        )
    except Exception as e:
        logger.exception(f"NameNode crashed: {e}")
```

---

## File 5: datanode0.py (Primary DataNode)

```python
#!/usr/bin/env python3
"""
DataNode 0 (Primary) - Storage node A.
Responsibilities:
- Store chunks on disk
- Compute and verify checksums
- Send heartbeats to NameNode
- Push replicas to secondary nodes
"""

import os
import json
import time
import threading
import hashlib
import logging
from flask import Flask, request, jsonify, send_file
import requests

# ========== SETUP ==========

BASE = os.path.dirname(os.path.abspath(__file__))
STORAGE = os.path.join(BASE, "storage_dn0")
INDEX = os.path.join(BASE, "chunks_index_dn0.json")
CONFIG_PATH = os.path.join(BASE, "config_primary.json")

os.makedirs(STORAGE, exist_ok=True)

# Load config
DEFAULT_CONFIG = {
    "node_id": "DataNode_0",
    "ip": "0.0.0.0",
    "port": 7000,
    "namenode_ip": "127.0.0.1",
    "namenode_port": 5000,
    "heartbeat_interval": 5,
    "debug": True
}

try:
    with open(CONFIG_PATH) as f:
        C = {**DEFAULT_CONFIG, **json.load(f)}
except:
    C = DEFAULT_CONFIG

NODE_ID = C["node_id"]
MY_IP = C["ip"]
MY_PORT = C["port"]
NAMENODE_IP = C["namenode_ip"]
NAMENODE_PORT = C["namenode_port"]
HEARTBEAT_INTERVAL = C.get("heartbeat_interval", 5)

# Logging
log_level = logging.DEBUG if C.get("debug", False) else logging.INFO
logging.basicConfig(
    level=log_level,
    format=f'%(asctime)s [{NODE_ID}] %(levelname)s: %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler(os.path.join(BASE, "datanode0.log"), mode='a')
    ]
)
logger = logging.getLogger(__name__)

# Flask app
app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 200 * 1024 * 1024

# Index management
index_lock = threading.Lock()

if os.path.exists(INDEX):
    with open(INDEX) as f:
        index = json.load(f)
else:
    index = {}

def persist_index():
    """Save index to disk."""
    tmp = INDEX + ".tmp"
    with index_lock:
        with open(tmp, "w") as f:
            json.dump(index, f, indent=2)
        os.replace(tmp, INDEX)

def sha256_stream(path):
    """Compute SHA256 of file."""
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()

# ========== ROUTES ==========

@app.route("/store_chunk", methods=["POST"])
def store_chunk():
    """Store a chunk."""
    try:
        chunk_file = request.files.get("chunk")
        chunk_id = request.form.get("chunk_id") or (chunk_file.filename if chunk_file else None)
        
        if not chunk_file or not chunk_id:
            return jsonify({"status": "error", "msg": "missing chunk"}), 400
        
        path = os.path.join(STORAGE, chunk_id)
        chunk_file.save(path)
        checksum = sha256_stream(path)
        
        with index_lock:
            index[chunk_id] = {
                "path": path,
                "checksum": checksum,
                "stored_at": time.time()
            }
            persist_index()
        
        logger.info(f"Stored chunk {chunk_id} checksum={checksum}")
        return jsonify({"status": "ok", "chunk_id": chunk_id, "checksum": checksum})
    
    except Exception as e:
        logger.exception(f"store_chunk error: {e}")
        return jsonify({"status": "error", "msg": str(e)}), 500

@app.route("/get_chunk", methods=["GET"])
def get_chunk():
    """Retrieve a chunk."""
    try:
        chunk_id = request.args.get("chunk_id")
        
        if not chunk_id:
            return jsonify({"status": "error", "msg": "missing chunk_id"}), 400
        
        with index_lock:
            rec = index.get(chunk_id)
        
        if not rec or not os.path.exists(rec.get("path", "")):
            return jsonify({"status": "error", "msg": "not found"}), 404
        
        return send_file(rec["path"], as_attachment=True)
    
    except Exception as e:
        logger.exception(f"get_chunk error: {e}")
        return jsonify({"status": "error", "msg": str(e)}), 500

@app.route("/list_chunks", methods=["GET"])
def list_chunks():
    """List all stored chunks."""
    try:
        with index_lock:
            chunks = {cid: rec.get("checksum") for cid, rec in index.items()}
        return jsonify({"chunks": chunks})
    except Exception as e:
        logger.exception(f"list_chunks error: {e}")
        return jsonify({"status": "error", "msg": str(e)}), 500

@app.route("/verify_chunk", methods=["GET"])
def verify_chunk():
    """Verify chunk integrity."""
    try:
        chunk_id = request.args.get("chunk_id")
        
        if not chunk_id:
            return jsonify({"status": "error", "msg": "missing chunk_id"}), 400
        
        with index_lock:
            rec = index.get(chunk_id)
        
        if not rec or not os.path.exists(rec.get("path", "")):
            return jsonify({"status": "error", "msg": "not found"}), 404
        
        actual = sha256_stream(rec["path"])
        expected = rec.get("checksum")
        ok = (actual == expected)
        
        if not ok:
            logger.error(f"Checksum mismatch: {chunk_id} expected={expected} actual={actual}")
        
        return jsonify({
            "status": "ok",
            "chunk_id": chunk_id,
            "ok": ok,
            "expected": expected,
            "actual": actual
        })
    
    except Exception as e:
        logger.exception(f"verify_chunk error: {e}")
        return jsonify({"status": "error", "msg": str(e)}), 500

# ========== HEARTBEAT ==========

def heartbeat_loop():
    """Send periodic heartbeats to NameNode."""
    backoff = HEARTBEAT_INTERVAL
    max_backoff = 30
    
    while True:
        try:
            url = f"http://{NAMENODE_IP}:{NAMENODE_PORT}/heartbeat"
            payload = {
                "node_id": NODE_ID,
                "ip": MY_IP,
                "port": MY_PORT
            }
            
            resp = requests.post(url, json=payload, timeout=5)
            
            if resp.status_code == 200:
                logger.debug("Heartbeat sent")
                backoff = HEARTBEAT_INTERVAL
            else:
                logger.warning(f"Heartbeat failed: {resp.status_code}")
                backoff = min(backoff * 2, max_backoff)
        
        except Exception as e:
            logger.warning(f"Heartbeat error: {e}")
            backoff = min(backoff * 2, max_backoff)
        
        time.sleep(backoff)

def register_on_start():
    """Register with NameNode on startup."""
    url = f"http://{NAMENODE_IP}:{NAMENODE_PORT}/register_datanode"
    payload = {
        "node_id": NODE_ID,
        "ip": MY_IP,
        "port": MY_PORT,
        "role": "datanode_primary"
    }
    
    for attempt in range(1, 6):
        try:
            resp = requests.post(url, json=payload, timeout=5)
            if resp.ok:
                logger.info(f"Registered successfully on attempt {attempt}")
                return True
        except Exception as e:
            logger.warning(f"Registration attempt {attempt} failed: {e}")
        
        time.sleep(attempt)
    
    logger.warning("Could not register with NameNode")
    return False

# ========== MAIN ==========

if __name__ == "__main__":
    logger.info("=" * 60)
    logger.info(f"Starting {NODE_ID}")
    logger.info("=" * 60)
    
    register_on_start()
    
    hb_thread = threading.Thread(target=heartbeat_loop, daemon=True)
    hb_thread.start()
    
    try:
        app.run(host=MY_IP, port=MY_PORT, debug=C.get("debug", False), threaded=True)
    except Exception as e:
        logger.exception(f"DataNode crashed: {e}")
```

---

## File 6: datanode1.py (Secondary DataNode)

```python
#!/usr/bin/env python3
"""
DataNode 1 (Secondary) - Storage node B (replica node).
"""

import os
import json
import time
import threading
import hashlib
import logging
import re
from flask import Flask, request, jsonify, send_file
import requests

# ========== SETUP ==========

BASE = os.path.dirname(os.path.abspath(__file__))
STORAGE = os.path.join(BASE, "storage_dn1")
INDEX = os.path.join(BASE, "chunks_index_dn1.json")
CONFIG_PATH = os.path.join(BASE, "config_secondary.json")

os.makedirs(STORAGE, exist_ok=True)

# Load config
DEFAULT_CONFIG = {
    "node_id": "DataNode_1",
    "ip": "0.0.0.0",
    "port": 7001,
    "namenode_ip": "127.0.0.1",
    "namenode_port": 5000,
    "heartbeat_interval": 5,
    "verify_interval": 120,
    "debug": True
}

try:
    with open(CONFIG_PATH) as f:
        C = {**DEFAULT_CONFIG, **json.load(f)}
except:
    C = DEFAULT_CONFIG

NODE_ID = C["node_id"]
MY_IP = C["ip"]
MY_PORT = C.get("port", 7001)
NAMENODE_IP = C["namenode_ip"]
NAMENODE_PORT = C["namenode_port"]
HEARTBEAT_INTERVAL = C.get("heartbeat_interval", 5)
VERIFY_INTERVAL = C.get("verify_interval", 120)

# Logging
log_level = logging.DEBUG if C.get("debug", False) else logging.INFO
logging.basicConfig(
    level=log_level,
    format=f'%(asctime)s [{NODE_ID}] %(levelname)s: %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler(os.path.join(BASE, "datanode1.log"), mode='a')
    ]
)
logger = logging.getLogger(__name__)

# Flask app
app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 200 * 1024 * 1024

# Index management
index_lock = threading.Lock()
SAFE_CHUNK_RE = re.compile(r'^[A-Za-z0-9._-]+$')

if os.path.exists(INDEX):
    try:
        with open(INDEX) as f:
            index = json.load(f)
    except:
        index = {}
else:
    index = {}

def persist_index():
    """Save index to disk."""
    tmp = INDEX + ".tmp"
    with index_lock:
        with open(tmp, "w") as f:
            json.dump(index, f, indent=2)
        os.replace(tmp, INDEX)

def sha256_bytes(data: bytes) -> str:
    """Compute SHA256 of bytes."""
    return hashlib.sha256(data).hexdigest()

def safe_chunk_id(cid: str) -> bool:
    """Validate chunk ID."""
    return isinstance(cid, str) and bool(SAFE_CHUNK_RE.match(cid))

# ========== ROUTES ==========

@app.route("/replicate_here", methods=["POST"])
def replicate_here():
    """Accept replica from primary."""
    try:
        chunk_file = request.files.get("chunk")
        chunk_id = request.form.get("chunk_id") or (chunk_file.filename if chunk_file else None)
        
        if not chunk_file or not chunk_id:
            return jsonify({"status": "error", "msg": "missing chunk"}), 400
        
        if not safe_chunk_id(chunk_id):
            return jsonify({"status": "error", "msg": "invalid chunk_id"}), 400
        
        path = os.path.join(STORAGE, chunk_id)
        data = chunk_file.read()
        
        with open(path, "wb") as f:
            f.write(data)
            f.flush()
            os.fsync(f.fileno())
        
        checksum = sha256_bytes(data)
        
        with index_lock:
            index[chunk_id] = {
                "path": path,
                "checksum": checksum,
                "replica": True,
                "stored_at": time.time()
            }
            persist_index()
        
        logger.info(f"Stored replica {chunk_id} checksum={checksum}")
        return jsonify({"status": "ok", "chunk_id": chunk_id, "checksum": checksum})
    
    except Exception as e:
        logger.exception(f"replicate_here error: {e}")
        return jsonify({"status": "error", "msg": str(e)}), 500

@app.route("/store_chunk", methods=["POST"])
def store_chunk():
    """Backwards-compatible chunk store endpoint."""
    return replicate_here()

@app.route("/get_chunk", methods=["GET"])
def get_chunk():
    """Retrieve a chunk."""
    try:
        chunk_id = request.args.get("chunk_id")
        
        if not chunk_id or not safe_chunk_id(chunk_id):
            return jsonify({"status": "error", "msg": "invalid chunk_id"}), 400
        
        with index_lock:
            rec = index.get(chunk_id)
        
        if not rec or not os.path.exists(rec.get("path", "")):
            return jsonify({"status": "error", "msg": "not found"}), 404
        
        return send_file(rec["path"], as_attachment=True)
    
    except Exception as e:
        logger.exception(f"get_chunk error: {e}")
        return jsonify({"status": "error", "msg": str(e)}), 500

@app.route("/list_chunks", methods=["GET"])
def list_chunks():
    """List stored chunks."""
    try:
        with index_lock:
            chunks = {cid: rec.get("checksum") for cid, rec in index.items()}
        return jsonify({"chunks": chunks})
    except Exception as e:
        logger.exception(f"list_chunks error: {e}")
        return jsonify({"status": "error", "msg": str(e)}), 500

@app.route("/verify_chunk", methods=["GET"])
def verify_chunk():
    """Verify chunk integrity."""
    try:
        chunk_id = request.args.get("chunk_id")
        
        if not chunk_id or not safe_chunk_id(chunk_id):
            return jsonify({"status": "error", "msg": "invalid chunk_id"}), 400
        
        with index_lock:
            rec = index.get(chunk_id)
        
        if not rec or not os.path.exists(rec.get("path", "")):
            return jsonify({"status": "error", "msg": "not found"}), 404
        
        with open(rec["path"], "rb") as f:
            data = f.read()
        
        actual = sha256_bytes(data)
        expected = rec.get("checksum")
        ok = (actual == expected)
        
        if not ok:
            logger.error(f"Checksum mismatch: {chunk_id}")
        
        return jsonify({
            "status": "ok",
            "chunk_id": chunk_id,
            "ok": ok,
            "expected": expected,
            "actual": actual
        })
    
    except Exception as e:
        logger.exception(f"verify_chunk error: {e}")
        return jsonify({"status": "error", "msg": str(e)}), 500

# ========== BACKGROUND TASKS ==========

def heartbeat_loop():
    """Send periodic heartbeats."""
    backoff = HEARTBEAT_INTERVAL
    max_backoff = 30
    failure_count = 0
    
    while True:
        try:
            url = f"http://{NAMENODE_IP}:{NAMENODE_PORT}/heartbeat"
            payload = {
                "node_id": NODE_ID,
                "ip": MY_IP,
                "port": MY_PORT
            }
            
            resp = requests.post(url, json=payload, timeout=5)
            
            if resp.status_code == 200:
                logger.debug("Heartbeat sent")
                failure_count = 0
                backoff = HEARTBEAT_INTERVAL
            else:
                logger.warning(f"Heartbeat failed: {resp.status_code}")
                failure_count += 1
                backoff = min(backoff * 2, max_backoff)
        
        except Exception as e:
            logger.warning(f"Heartbeat error: {e}")
            failure_count += 1
            backoff = min(backoff * 2, max_backoff)
        
        time.sleep(backoff)

def periodic_verifier():
    """Periodically verify chunk integrity."""
    logger.info("Periodic verifier started")
    
    while True:
        try:
            time.sleep(VERIFY_INTERVAL)
            
            with index_lock:
                items = list(index.items())
            
            logger.debug(f"Verifying {len(items)} chunks")
            
            for chunk_id, rec in items:
                try:
                    if not os.path.exists(rec.get("path", "")):
                        logger.error(f"Chunk file missing: {chunk_id}")
                        continue
                    
                    with open(rec["path"], "rb") as f:
                        data = f.read()
                    
                    actual = sha256_bytes(data)
                    
                    if actual != rec.get("checksum"):
                        logger.error(f"Checksum mismatch: {chunk_id}")
                    else:
                        logger.debug(f"Verified {chunk_id} OK")
                
                except Exception as e:
                    logger.exception(f"Verification error for {chunk_id}: {e}")
        
        except Exception as e:
            logger.exception(f"Periodic verifier error: {e}")

def register_on_start():
    """Register with NameNode."""
    url = f"http://{NAMENODE_IP}:{NAMENODE_PORT}/register_datanode"
    payload = {
        "node_id": NODE_ID,
        "ip": MY_IP,
        "port": MY_PORT,
        "role": "datanode_secondary"
    }
    
    for attempt in range(1, 6):
        try:
            resp = requests.post(url, json=payload, timeout=5)
            if resp.ok:
                logger.info(f"Registered successfully on attempt {attempt}")
                return True
        except Exception as e:
            logger.warning(f"Registration attempt {attempt} failed: {e}")
        
        time.sleep(attempt)
    
    logger.warning("Could not register with NameNode")
    return False

# ========== MAIN ==========

if __name__ == "__main__":
    logger.info("=" * 60)
    logger.info(f"Starting {NODE_ID}")
    logger.info("=" * 60)
    
    register_on_start()
    
    hb_thread = threading.Thread(target=heartbeat_loop, daemon=True)
    hb_thread.start()
    
    ver_thread = threading.Thread(target=periodic_verifier, daemon=True)
    ver_thread.start()
    
    try:
        app.run(host=MY_IP, port=MY_PORT, debug=C.get("debug", False), threaded=True)
    except Exception as e:
        logger.exception(f"DataNode crashed: {e}")
```

---

## File 7: client.py (Client Web Interface)

```python
#!/usr/bin/env python3
"""
Client - Flask web interface for uploading, downloading, and viewing HDFS state.
"""

import os
import json
import logging
from flask import Flask, request, render_template, jsonify, send_file
import requests
import io

# ========== SETUP ==========

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_PATH = os.path.join(BASE_DIR, "config.json")

# Load config
try:
    with open(CONFIG_PATH, "r") as f:
        CONFIG = json.load(f)
except:
    CONFIG = {
        "namenode_ip": "127.0.0.1",
        "namenode_port": 5000,
        "ip": "0.0.0.0",
        "port": 5001,
        "debug": True
    }

NAMENODE_URL = f"http://{CONFIG.get('namenode_ip', '127.0.0.1')}:{CONFIG.get('namenode_port', 5000)}"
CLIENT_PORT = CONFIG.get("port", 5001)

# Logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s [Client] %(levelname)s: %(message)s',
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler(os.path.join(BASE_DIR, "client.log"), mode='a')
    ]
)
logger = logging.getLogger(__name__)

# Flask app
app = Flask(__name__, template_folder="templates")
app.config['MAX_CONTENT_LENGTH'] = 500 * 1024 * 1024  # 500MB

# ========== ROUTES ==========

@app.route("/", methods=["GET"])
def index():
    """Serve dashboard."""
    try:
        resp = requests.get(f"{NAMENODE_URL}/metadata", timeout=5)
        metadata = resp.json() if resp.ok else {}
    except Exception as e:
        logger.warning(f"Could not fetch metadata: {e}")
        metadata = {"error": str(e)}
    
    return render_template("index.html", metadata=json.dumps(metadata))

@app.route("/upload", methods=["POST"])
def upload():
    """Handle file upload."""
    try:
        file_obj = request.files.get("file")
        if not file_obj:
            return jsonify({"status": "error", "msg": "no file"}), 400
        
        filename = request.form.get("filename") or file_obj.filename
        
        # Forward to NameNode
        files = {"file": (filename, file_obj.read())}
        data = {"filename": filename}
        
        resp = requests.post(
            f"{NAMENODE_URL}/upload",
            files=files,
            data=data,
            timeout=120
        )
        
        if resp.ok:
            return jsonify(resp.json())
        else:
            return jsonify({"status": "error", "msg": resp.text}), 500
    
    except Exception as e:
        logger.exception(f"Upload error: {e}")
        return jsonify({"status": "error", "msg": str(e)}), 500

@app.route("/download", methods=["POST"])
def download():
    """Handle file download."""
    try:
        filename = request.form.get("filename")
        if not filename:
            return jsonify({"status": "error", "msg": "missing filename"}), 400
        
        # Get metadata
        resp_meta = requests.get(f"{NAMENODE_URL}/metadata", timeout=5)
        if not resp_meta.ok:
            return jsonify({"status": "error", "msg": "could not get metadata"}), 500
        
        metadata = resp_meta.json()
        
        if filename not in metadata.get("files", {}):
            return jsonify({"status": "error", "msg": "file not found"}), 404
        
        file_meta = metadata["files"][filename]
        chunks = []
        
        # Download chunks
        for chunk_id, nodes in file_meta.get("chunks", {}).items():
            content = None
            
            # Try each replica
            for node_id in nodes:
                dn = metadata["datanodes"].get(node_id, {})
                if not dn:
                    continue
                
                try:
                    resp_chunk = requests.get(
                        f"http://{dn['ip']}:{dn['port']}/get_chunk",
                        params={"chunk_id": chunk_id},
                        timeout=30
                    )
                    
                    if resp_chunk.status_code == 200:
                        content = resp_chunk.content
                        logger.debug(f"Downloaded {chunk_id} from {node_id}")
                        break
                
                except Exception as e:
                    logger.warning(f"Failed to download {chunk_id} from {node_id}: {e}")
                    continue
            
            if content is None:
                return jsonify({
                    "status": "error",
                    "msg": f"Could not download chunk {chunk_id}"
                }), 500
            
            chunks.append(content)
        
        # Reconstruct file
        file_data = b"".join(chunks)
        
        return send_file(
            io.BytesIO(file_data),
            as_attachment=True,
            download_name=filename,
            mimetype="application/octet-stream"
        )
    
    except Exception as e:
        logger.exception(f"Download error: {e}")
        return jsonify({"status": "error", "msg": str(e)}), 500

@app.route("/metadata", methods=["GET"])
def get_metadata():
    """Proxy metadata from NameNode."""
    try:
        resp = requests.get(f"{NAMENODE_URL}/metadata", timeout=5)
        return jsonify(resp.json() if resp.ok else {})
    except Exception as e:
        logger.exception(f"Metadata error: {e}")
        return jsonify({"status": "error", "msg": str(e)}), 500

@app.route("/files", methods=["GET"])
def list_files():
    """List uploaded files."""
    try:
        resp = requests.get(f"{NAMENODE_URL}/list_files", timeout=5)
        return jsonify(resp.json() if resp.ok else {"files": []})
    except Exception as e:
        logger.exception(f"List files error: {e}")
        return jsonify({"files": []})

# ========== MAIN ==========

if __name__ == "__main__":
    logger.info("=" * 60)
    logger.info("Starting Client Web Interface")
    logger.info(f"NameNode: {NAMENODE_URL}")
    logger.info("=" * 60)
    
    app.run(
        host=CONFIG.get("ip", "0.0.0.0"),
        port=CLIENT_PORT,
        debug=CONFIG.get("debug", False)
    )
```

---

## File 8: templates/index.html (Web Dashboard)

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mini HDFS Dashboard</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            padding: 20px;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        header {
            background: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            margin-bottom: 20px;
        }
        
        header h1 {
            color: #667eea;
            margin-bottom: 10px;
        }
        
        .status-bar {
            display: flex;
            gap: 20px;
            margin-top: 15px;
            flex-wrap: wrap;
        }
        
        .status-item {
            display: flex;
            align-items: center;
            gap: 8px;
            padding: 8px 12px;
            background: #f0f0f0;
            border-radius: 5px;
        }
        
        .status-dot {
            width: 12px;
            height: 12px;
            border-radius: 50%;
            background: #4caf50;
        }
        
        .status-dot.offline {
            background: #f44336;
        }
        
        .main-grid {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 20px;
            margin-bottom: 20px;
        }
        
        @media (max-width: 768px) {
            .main-grid {
                grid-template-columns: 1fr;
            }
        }
        
        .card {
            background: white;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            padding: 20px;
        }
        
        .card h2 {
            color: #667eea;
            margin-bottom: 15px;
            font-size: 18px;
            border-bottom: 2px solid #667eea;
            padding-bottom: 10px;
        }
        
        .upload-area {
            border: 2px dashed #667eea;
            border-radius: 8px;
            padding: 30px;
            text-align: center;
            cursor: pointer;
            transition: all 0.3s;
        }
        
        .upload-area:hover {
            background: #f5f5f5;
            border-color: #764ba2;
        }
        
        .upload-area.dragover {
            background: #e3f2fd;
            border-color: #764ba2;
        }
        
        .upload-area p {
            color: #666;
            margin-bottom: 10px;
        }
        
        input[type="file"] {
            display: none;
        }
        
        .btn {
            display: inline-block;
            padding: 10px 20px;
            background: #667eea;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 14px;
            transition: all 0.3s;
        }
        
        .btn:hover {
            background: #764ba2;
            transform: translateY(-2px);
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.2);
        }
        
        .btn-small {
            padding: 6px 12px;
            font-size: 12px;
        }
        
        .btn-danger {
            background: #f44336;
        }
        
        .btn-danger:hover {
            background: #d32f2f;
        }
        
        .file-list {
            list-style: none;
        }
        
        .file-item {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 12px;
            margin-bottom: 10px;
            background: #f9f9f9;
            border-radius: 5px;
            border-left: 4px solid #667eea;
        }
        
        .file-info {
            flex: 1;
        }
        
        .file-name {
            font-weight: bold;
            color: #333;
            margin-bottom: 4px;
        }
        
        .file-details {
            font-size: 12px;
            color: #999;
        }
        
        .file-actions {
            display: flex;
            gap: 8px;
        }
        
        .datanode {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 12px;
            margin-bottom: 8px;
            background: #f9f9f9;
            border-radius: 5px;
            border-left: 4px solid #4caf50;
        }
        
        .datanode.offline {
            border-left-color: #f44336;
            opacity: 0.6;
        }
        
        .datanode-name {
            font-weight: bold;
            color: #333;
        }
        
        .datanode-addr {
            font-size: 12px;
            color: #999;
        }
        
        .datanode-status {
            display: flex;
            align-items: center;
            gap: 8px;
        }
        
        .chunk-grid {
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(100px, 1fr));
            gap: 10px;
            margin-top: 15px;
        }
        
        .chunk-box {
            background: #e3f2fd;
            border: 1px solid #667eea;
            padding: 10px;
            border-radius: 5px;
            text-align: center;
            font-size: 12px;
            word-break: break-all;
        }
        
        .progress-bar {
            width: 100%;
            height: 20px;
            background: #e0e0e0;
            border-radius: 10px;
            overflow: hidden;
            margin-top: 10px;
        }
        
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #667eea, #764ba2);
            width: 0%;
            transition: width 0.3s;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 12px;
        }
        
        .alert {
            padding: 15px;
            margin-bottom: 15px;
            border-radius: 5px;
            border-left: 4px solid;
        }
        
        .alert-success {
            background: #c8e6c9;
            border-color: #4caf50;
            color: #2e7d32;
        }
        
        .alert-error {
            background: #ffcdd2;
            border-color: #f44336;
            color: #b71c1c;
        }
        
        .alert-info {
            background: #bbdefb;
            border-color: #2196f3;
            color: #0d47a1;
        }
        
        .tabs {
            display: flex;
            gap: 10px;
            margin-bottom: 15px;
            border-bottom: 2px solid #e0e0e0;
        }
        
        .tab {
            padding: 10px 15px;
            background: none;
            border: none;
            cursor: pointer;
            color: #999;
            font-weight: bold;
            border-bottom: 3px solid transparent;
            transition: all 0.3s;
        }
        
        .tab.active {
            color: #667eea;
            border-bottom-color: #667eea;
        }
        
        .tab-content {
            display: none;
        }
        
        .tab-content.active {
            display: block;
        }
        
        .spinner {
            display: inline-block;
            width: 12px;
            height: 12px;
            border: 2px solid #f3f3f3;
            border-top: 2px solid #667eea;
            border-radius: 50%;
            animation: spin 1s linear infinite;
        }
        
        @keyframes spin {
            0% { transform: rotate(0deg); }
            100% { transform: rotate(360deg); }
        }
        
        .empty-state {
            text-align: center;
            padding: 40px 20px;
            color: #999;
        }
        
        .empty-state p {
            margin: 10px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <!-- Header -->
        <header>
            <h1>🎛️ Mini HDFS Dashboard</h1>
            <p>Distributed File Storage System</p>
            <div class="status-bar">
                <div class="status-item">
                    <span class="status-dot" id="status-dot"></span>
                    <span id="status-text">System Status</span>
                </div>
                <div class="status-item">
                    <span id="datanode-count">0</span> DataNodes Online
                </div>
                <div class="status-item">
                    <span id="file-count">0</span> Files Uploaded
                </div>
                <div class="status-item">
                    <span id="chunk-count">0</span> Chunks
                </div>
            </div>
        </header>
        
        <!-- Main Content -->
        <div class="main-grid">
            <!-- Upload Section -->
            <div class="card">
                <h2>📤 Upload File</h2>
                <div class="upload-area" id="uploadArea">
                    <p>📁 Drag & drop your file here or click to select</p>
                    <small>Max file size: 500MB | Chunk size: 2MB | Replication: 2</small>
                </div>
                <input type="file" id="fileInput">
                <div id="uploadProgress" style="display: none; margin-top: 15px;">
                    <p id="progressText">Uploading: <span id="progressPercent">0</span>%</p>
                    <div class="progress-bar">
                        <div class="progress-fill" id="progressFill"></div>
                    </div>
                </div>
                <div id="uploadAlert" style="margin-top: 15px;"></div>
            </div>
            
            <!-- Files Section -->
            <div class="card">
                <h2>📂 Files</h2>
                <div id="filesContainer">
                    <div class="empty-state">
                        <p>📭 No files uploaded yet</p>
                    </div>
                </div>
            </div>
        </div>
        
        <!-- DataNodes & Metadata -->
        <div class="main-grid">
            <!-- DataNodes -->
            <div class="card">
                <h2>🖥️ DataNodes</h2>
                <div id="datanodesContainer">
                    <div class="empty-state">
                        <p>⏳ Waiting for DataNodes...</p>
                    </div>
                </div>
            </div>
            
            <!-- System Info -->
            <div class="card">
                <h2>ℹ️ System Information</h2>
                <div id="systemInfo">
                    <div class="empty-state">
                        <p>⏳ Loading system information...</p>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <script>
        const API_BASE = '';
        const REFRESH_INTERVAL = 5000; // 5 seconds
        
        let currentMetadata = {};
        
        // ========== Upload Handlers ==========
        
        const uploadArea = document.getElementById('uploadArea');
        const fileInput = document.getElementById('fileInput');
        const uploadAlert = document.getElementById('uploadAlert');
        const uploadProgress = document.getElementById('uploadProgress');
        
        uploadArea.addEventListener('click', () => fileInput.click());
        
        uploadArea.addEventListener('dragover', (e) => {
            e.preventDefault();
            uploadArea.classList.add('dragover');
        });
        
        uploadArea.addEventListener('dragleave', () => {
            uploadArea.classList.remove('dragover');
        });
        
        uploadArea.addEventListener('drop', (e) => {
            e.preventDefault();
            uploadArea.classList.remove('dragover');
            const files = e.dataTransfer.files;
            if (files.length > 0) {
                fileInput.files = files;
                handleFileUpload();
            }
        });
        
        fileInput.addEventListener('change', handleFileUpload);
        
        async function handleFileUpload() {
            const file = fileInput.files[0];
            if (!file) return;
            
            const formData = new FormData();
            formData.append('file', file);
            formData.append('filename', file.name);
            
            uploadAlert.innerHTML = '';
            uploadProgress.style.display = 'block';
            
            try {
                const response = await fetch(`${API_BASE}/upload`, {
                    method: 'POST',
                    body: formData
                });
                
                const result = await response.json();
                
                if (result.status === 'ok') {
                    showAlert('File uploaded successfully!', 'success', uploadAlert);
                    fileInput.value = '';
                    refreshMetadata();
                } else {
                    showAlert('Upload failed: ' + result.msg, 'error', uploadAlert);
                }
            } catch (error) {
                showAlert('Upload error: ' + error.message, 'error', uploadAlert);
            } finally {
                uploadProgress.style.display = 'none';
            }
        }
        
        // ========== Download Handlers ==========
        
        function downloadFile(filename) {
            const form = document.createElement('form');
            form.method = 'POST';
            form.action = `${API_BASE}/download`;
            
            const input = document.createElement('input');
            input.type = 'hidden';
            input.name = 'filename';
            input.value = filename;
            
            form.appendChild(input);
            document.body.appendChild(form);
            form.submit();
            document.body.removeChild(form);
        }
        
        // ========== UI Updates ==========
        
        function showAlert(message, type, container) {
            container.innerHTML = `<div class="alert alert-${type}">${message}</div>`;
        }
        
        function updateStatus() {
            const statusDot = document.getElementById('status-dot');
            const statusText = document.getElementById('status-text');
            
            const alive = currentMetadata.alive_count || 0;
            const total = currentMetadata.total_count || 0;
            
            if (alive > 0) {
                statusDot.classList.remove('offline');
                statusText.textContent = 'System Online';
            } else {
                statusDot.classList.add('offline');
                statusText.textContent = 'System Offline';
            }
        }
        
        function updateDataNodes() {
            const container = document.getElementById('datanodesContainer');
            const datanodes = currentMetadata.datanodes || {};
            
            if (Object.keys(datanodes).length === 0) {
                container.innerHTML = '<div class="empty-state"><p>⏳ No DataNodes connected</p></div>';
                return;
            }
            
            let html = '';
            for (const [nodeId, info] of Object.entries(datanodes)) {
                const isAlive = (Date.now() / 1000 - info.last_heartbeat) < 15;
                const cls = isAlive ? '' : 'offline';
                const status = isAlive ? '✅ Online' : '⏹️ Offline';
                
                html += `
                    <div class="datanode ${cls}">
                        <div>
                            <div class="datanode-name">${nodeId}</div>
                            <div class="datanode-addr">${info.ip}:${info.port}</div>
                        </div>
                        <div class="datanode-status">${status}</div>
                    </div>
                `;
            }
            container.innerHTML = html;
            
            document.getElementById('datanode-count').textContent = 
                Object.values(datanodes).filter(d => (Date.now() / 1000 - d.last_heartbeat) < 15).length;
        }
        
        function updateFiles() {
            const container = document.getElementById('filesContainer');
            const files = currentMetadata.files || {};
            
            if (Object.keys(files).length === 0) {
                container.innerHTML = '<div class="empty-state"><p>📭 No files uploaded yet</p></div>';
                return;
            }
            
            let html = '<ul class="file-list">';
            for (const [filename, meta] of Object.entries(files)) {
                const numChunks = meta.num_chunks || 0;
                const size = formatBytes(meta.size || 0);
                
                html += `
                    <li class="file-item">
                        <div class="file-info">
                            <div class="file-name">📄 ${filename}</div>
                            <div class="file-details">${numChunks} chunks | ${size}</div>
                        </div>
                        <div class="file-actions">
                            <button class="btn btn-small" onclick="downloadFile('${filename}')">Download</button>
                        </div>
                    </li>
                `;
            }
            html += '</ul>';
            container.innerHTML = html;
            
            document.getElementById('file-count').textContent = Object.keys(files).length;
            
            // Count chunks
            let totalChunks = 0;
            for (const file of Object.values(files)) {
                totalChunks += file.num_chunks || 0;
            }
            document.getElementById('chunk-count').textContent = totalChunks;
        }
        
        function updateSystemInfo() {
            const container = document.getElementById('systemInfo');
            const html = `
                <p><strong>Chunk Size:</strong> ${formatBytes(currentMetadata.chunk_size || 0)}</p>
                <p><strong>Replication Factor:</strong> ${currentMetadata.replication_factor || 2}</p>
                <p><strong>Alive DataNodes:</strong> ${currentMetadata.alive_count || 0} / ${currentMetadata.total_count || 0}</p>
                <p><strong>Total Files:</strong> ${Object.keys(currentMetadata.files || {}).length}</p>
                <p><strong>Total Chunks:</strong> <span id="chunk-count-info">0</span></p>
                <hr style="margin: 15px 0; border: none; border-top: 1px solid #e0e0e0;">
                <p style="font-size: 12px; color: #999;">Last updated: <span id="last-updated">-</span></p>
            `;
            container.innerHTML = html;
            
            // Count chunks
            let totalChunks = 0;
            for (const file of Object.values(currentMetadata.files || {})) {
                totalChunks += file.num_chunks || 0;
            }
            document.getElementById('chunk-count-info').textContent = totalChunks;
            
            const now = new Date().toLocaleTimeString();
            document.getElementById('last-updated').textContent = now;
        }
        
        function formatBytes(bytes) {
            if (bytes === 0) return '0 B';
            const k = 1024;
            const sizes = ['B', 'KB', 'MB', 'GB'];
            const i = Math.floor(Math.log(bytes) / Math.log(k));
            return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i];
        }
        
        // ========== Refresh Metadata ==========
        
        async function refreshMetadata() {
            try {
                const response = await fetch(`${API_BASE}/metadata`);
                currentMetadata = await response.json();
                
                updateStatus();
                updateDataNodes();
                updateFiles();
                updateSystemInfo();
            } catch (error) {
                console.error('Metadata refresh error:', error);
            }
        }
        
        // Initial load and periodic refresh
        refreshMetadata();
        setInterval(refreshMetadata, REFRESH_INTERVAL);
    </script>
</body>
</html>
```

---

## Running the Project

### Start Order (use separate terminals):

1. **Start NameNode:**
   ```bash
   python namenode.py
   ```

2. **Start DataNode 0:**
   ```bash
   python datanode0.py
   ```

3. **Start DataNode 1:**
   ```bash
   python datanode1.py
   ```

4. **Start Client:**
   ```bash
   python client.py
   ```

5. **Open Dashboard:**
   Navigate to `http://localhost:5001`

### Key Features:

✅ **File Chunking** - 2MB chunks
✅ **Replication** - Factor of 2
✅ **Heartbeat Monitoring** - Automatic failure detection
✅ **Web Dashboard** - Real-time visualization
✅ **Upload/Download** - Full file lifecycle
✅ **Checksum Verification** - Data integrity
✅ **Re-replication** - Automatic recovery

---

## Project Structure Benefits

1. **Modularity** - Each component is independent
2. **Scalability** - Easy to add more datanodes
3. **Reliability** - Replication and health checks
4. **Observability** - Comprehensive logging
5. **User-friendly** - Intuitive web interface

