#!/usr/bin/env python3
"""
Unit and Integration Tests for FieldAI Backend Server
"""

import unittest
import os
import sys
import tempfile

# Add backend directory to sys.path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    from fastapi.testclient import TestClient
    from server import app, init_db
    FASTAPI_AVAILABLE = True
except ImportError:
    FASTAPI_AVAILABLE = False
    TestClient = None
    app = None

class TestFieldAIServer(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not FASTAPI_AVAILABLE:
            raise unittest.SkipTest("FastAPI not installed in current environment. Install via 'pip install -r backend/requirements.txt'.")
        cls.client = TestClient(app)

    def test_health_check(self):
        response = self.client.get("/health")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "online")
        self.assertEqual(data["service"], "FieldAI Cloud Backend")

    def test_auth_login(self):
        response = self.client.post("/api/v1/auth/login", json={
            "email": "field_worker@fieldai.org",
            "password": "secure_password_123"
        })
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("access_token", data)
        self.assertEqual(data["email"], "field_worker@fieldai.org")

    def test_auth_register(self):
        response = self.client.post("/api/v1/auth/register", json={
            "email": "new_agronomist@fieldai.org",
            "full_name": "Dr. Sarah Adams",
            "password": "secure_password_123"
        })
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("access_token", data)
        self.assertEqual(data["full_name"], "Dr. Sarah Adams")

    def test_rag_chat_early_blight(self):
        response = self.client.post("/api/v1/chat", json={
            "message": "How do I treat early blight concentric rings on tomatoes?",
            "context_crop": "Tomato"
        })
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("Alternaria solani", data["answer"])
        self.assertTrue(len(data["sources"]) > 0)

    def test_rag_chat_dosage(self):
        response = self.client.post("/api/v1/chat", json={
            "message": "What is the dosage calculation for a 16 liter knapsack sprayer?",
            "context_crop": "Tomato"
        })
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("16-liter knapsack", data["answer"])

    def test_sync_observations(self):
        payload = {
            "batch_id": "batch_test_001",
            "observations": [
                {
                    "client_id": "obs_unit_1",
                    "crop": "Tomato",
                    "condition_name": "Early Blight",
                    "confidence": 92.5,
                    "severity": "Moderate",
                    "latitude": 9.03,
                    "longitude": 38.74,
                    "notes": "Spotted on lower leaves"
                }
            ]
        }
        response = self.client.post("/api/v1/sync", json=payload)
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertEqual(data["status"], "success")
        self.assertEqual(data["received_count"], 1)

    def test_analytics_summary(self):
        response = self.client.get("/api/v1/analytics/summary")
        self.assertEqual(response.status_code, 200)
        data = response.json()
        self.assertIn("risk_score", data)
        self.assertIn("disease_distribution", data)
        self.assertIn("total_regional_samples", data)

if __name__ == "__main__":
    unittest.main()
