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
         
                    # 3. Running pod ka naam nikal lein
                    MASTER_POD=$(kubectl get pods -l app=jmeter-master -o jsonpath={.items[0].metadata.name})
                    echo "Master Pod is: $MASTER_POD"
         
                    # 4. Job ke complete hone ka wait karein (test poora chalne dein)
                    kubectl wait --for=condition=complete job/jmeter-master --timeout=600s
         
                    # 5. Test khatam hone ke foran baad, jab tak pod 'Completed' state mein hai (aur abhi delete nahi hua), 
                    # tab tak hum logs ya direct cat command se result file ka data Jenkins workspace mein nikal sakte hain!
                    kubectl exec $MASTER_POD -- cat /results/results.jtl > ./results.jtl || true
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
