resource "aws_db_instance" "postgresql" {
  db_name = local.db_name
  engine = local.db_type
  engine_version = "10.17" // TODO: latest engine version is 13.7
  allocated_storage = 10  // TODO: what this do?
  storage_type = "gp2"
  instance_class = "db.t3.micro"
  username =  local.db_username
  password = local.db_password
  port = 5432
  publicly_accessible = true  // TODO
  skip_final_snapshot = true

  // TODO: add tags
  vpc_security_group_ids = [aws_security_group.gtd_sg.id]

}
