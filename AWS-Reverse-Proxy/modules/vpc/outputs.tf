output "vpc_id"                  { value = aws_vpc.main.id }
output "public_subnet_ids"       { value = aws_subnet.public[*].id }
output "private_web_subnet_ids"  { value = aws_subnet.private_web[*].id }
output "private_data_subnet_ids" { value = aws_subnet.private_data[*].id }
output "nat_gateway_id"          { value = aws_nat_gateway.nat.id }
