resource "google_secret_manager_secret" "secret" {
  project   = "my-gcp-project"
  secret_id = "my-secret"

  replication {
    user_managed {
      replicas {
        location = "europe-west2"
      }
    }
  }
}

resource "google_secret_manager_secret_version" "version" {
  secret                 = google_secret_manager_secret.secret.id
  secret_data_wo         = var.secret_string
  secret_data_wo_version = parseint(substr(sha256(var.secret_string), 0, 4), 16)
}
