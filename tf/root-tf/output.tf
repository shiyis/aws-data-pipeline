output "codepipeline" {
  description = "The full `aws_codepipeline` object."
  value       = module.codepipeline.codepipeline
}

output "codebuild" {
  description = "The full `aws_codebuild_project` object."
  value       = module.codepipeline.codebuild
}