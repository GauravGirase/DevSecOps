@Library('Jenkins_shared_library') _
def COLOR_MAP = [
    'FAILURE' : 'danger',
    'SUCCESS' : 'good'
]

pipeline{
    agent any
    parameters {
        choice(name: 'action', choices: 'create\ndelete', description: 'Select action to perform (create/delete).')
        
        string(name: 'gitUrl', defaultValue: 'https://github.com/harishnshetty/3-tier-jenkins-shared-libraries-devsecops-project.git', description: 'Git URL')
        string(name: 'gitBranch', defaultValue: 'frontend', description: 'Git Branch')

        string(name: 'projectName', defaultValue: 'frontend', description: 'Project Name')
        string(name: 'projectKey', defaultValue: 'frontend', description: 'Project Key')

        string(name: 'dockerHubUsername', defaultValue: 'harishnshetty', description: 'Docker Hub Username')
        string(name: 'dockerImageName', defaultValue: 'frontend-signed', description: 'Docker Image Name')

        string(name: 'gitUserConfigName', defaultValue: 'harishn', description: 'Git User Name')
        string(name: 'gitUserConfigEmail', defaultValue: 'harishn662@gmail.com', description: 'Git User Email')
        string(name: 'gitUserName', defaultValue: 'harishnshetty', description: 'Git User Name')
        string(name: 'gitPassword', defaultValue: 'github-token', description: 'Git Password')

        string(name: 'slackChannel', defaultValue: '#jenkins-shared-devsecops', description: 'Slack Channel')
        string(name: 'emailAddress', defaultValue: 'harishn662@gmail.com', description: 'Email Address')
    }

    tools{
        jdk 'jdk17'
        nodejs 'node20'
    }
    environment {
        SCANNER_HOME = tool 'sonar-scanner'
        CONTAINER_PORT = 80
        EXPOSE_PORT = 80
        BRANCH = 'deployment'
        MANIFESTFILENAME = '05-three-tier-app/11-frontend-blue.yml'
        sonarServer = 'sonar-server'
        sonarqubeCredentialsId = 'sonar-token'

    }
    stages{

        stage('Clean Workspace'){
            steps{
                cleanWorkspace()
            }
        }
        stage('checkout from Git'){
            when { expression { params.action == 'create'}}    

            steps{
                checkoutGit(params.gitUrl, params.gitBranch)
            }
        }
        stage('gitleak'){
            when { expression { params.action == 'create'}}    
            steps{
                gitleak()
            }
        }
        stage('sonarqube Analysis'){
        when { expression { params.action == 'create'}}    
            steps{
                sonarqubeAnalysis(sonarServer)
            }
        }

        stage('sonarqube QualitGate'){
        when { expression { params.action == 'create'}}    
            steps{
                sonarqubequalitygate(sonarqubeCredentialsId)
                }
            }
        
        stage('npm install'){
        when { expression { params.action == 'create'}}    
            steps{
                npmInstall()
            }
        }
        
        stage('Trivy file scan'){
        when { expression { params.action == 'create'}}    
            steps{
                trivyFs()
            }
        }


        stage('OWASP FS SCAN') {
            when { expression { params.action == 'create'} }
            steps {
                owaspdpcheck()
            }
        }



        stage('Docker Build'){
        when { expression { params.action == 'create'}}    
            steps{
                dockerBuild()
            }
        }


        stage('Trivy Image Scan'){
        when { expression { params.action == 'create'}}    
            steps{
                trivyImage()
            }
        }

        stage('Docker Push To DockerHub'){
        when { expression { params.action == 'create'}}    
            steps{
                dockerPush()
            }
        }

        stage('Docker Run Container'){
        when { expression { params.action == 'create'}}    
            steps{
                dockerRun()
            }
        }

        stage('SBOM and Cosign Attestation'){
            when { expression { params.action == 'create'}}    
            steps{
                trivyCosignEnforce()
            }
        }


        stage('Manual Approval') {
            steps {
                manualwithslack()
            }
        }



        stage('update k8s deployment frontend file') {
            when {
                allOf {
                    expression { env.APPROVED == "true" }
                    expression { params.action == 'create' }
                }
            }
            steps {
                updateK8sDeploymentFile()
            }
        }
    }

    post {
        always {
            script {

                def buildStatus = currentBuild.currentResult

                zpostslack(buildStatus)
                zpostemail(buildStatus, params.emailAddress)

            }
        }
    }
}