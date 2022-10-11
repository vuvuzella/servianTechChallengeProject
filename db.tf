resource "aws_db_instance" "postgresql" {
  db_name = var.db_name
  engine = var.db_type
  engine_version = "10.17"
  allocated_storage = 10
  storage_type = "gp2"
  instance_class = "db.t3.micro"
  username =  var.db_username
  password = var.db_password
  port = 5432
  publicly_accessible = true
  skip_final_snapshot = true

  // TODO: add tags
  vpc_security_group_ids = [aws_security_group.gtd_sg.id]

}
