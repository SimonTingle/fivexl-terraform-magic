resource "local_file" "games" {
	filename = "/Users/simontingle/Desktop/WORK/PROGRAMMING/TEST_PROJECTS/coursera/terraform-labs/fav_games.txt"
	sensitive_content  = "fifa 2021"
	file_permission = "0755"
}
