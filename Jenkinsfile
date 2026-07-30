pipeline {
    agent any
    stages {
        stage('1. Push Script to Kubernetes') {
            steps {
                sh 'kubectl create configmap jmeter-script-config --from-file=test-script.jmx --dry-run=client -o yaml | kubectl apply -f -'
            }
        }
        stage('2. Start & Scale Workers') {
            steps {
                sh 'kubectl apply -f worker.yaml'
                sh 'kubectl scale deployment jmeter-worker --replicas=3'
                sh 'kubectl rollout status deployment/jmeter-worker'
            }
        }
        stage('3. Run Load Test & Get Results') {
            steps {
                sh '''
                    # 1. Master job apply karein
                    kubectl apply -f master.yaml
         
                    # 2. Pod ke active hone ka wait karein
                    echo "Waiting for master pod to start..."
                    sleep 5
         
                    # 3. Pod ka naam nikal lein
                    MASTER_POD=$(kubectl get pods -l app=jmeter-master -o jsonpath={.items[0].metadata.name})
                    echo "Master Pod is: $MASTER_POD"
         
                    # 4. Job ke complete hone ka wait karein
                    kubectl wait --for=condition=complete job/jmeter-master --timeout=600s
         
                    # 5. Pod complete hone ke BAAD kubectl cp kaam nahi karta, 
                    # isliye hum pod ke logs se result capture karenge ya fir master container 
                    # ko bolenge ki woh result print kare.
                    kubectl logs $MASTER_POD > ./results.jtl
                '''
            }
        }
    }
    post {
        always {
            sh 'kubectl delete -f master.yaml || true'
            sh 'kubectl delete -f worker.yaml || true'
            perfReport 'results.jtl' 
        }
    }
}
