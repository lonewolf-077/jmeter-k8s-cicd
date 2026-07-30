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
         
                    # 4. Background mein loop chalayein jo jese hi results.jtl file banaye, use copy kar le (jab tak pod alive hai)
                    while kubectl get pod $MASTER_POD 2>&1 | grep -q "Running"; do
                        kubectl cp ${MASTER_POD}:/results/results.jtl ./results.jtl 2>/dev/null || true
                        sleep 2
                    done
         
                    # 5. Aakhri baar job ke complete hone ka wait karein taaki pipeline sync rahe
                    kubectl wait --for=condition=complete job/jmeter-master --timeout=600s || true
                    
                    # 6. Ek aakhri baar copy try karein taaki koi data miss na ho
                    kubectl cp ${MASTER_POD}:/results/results.jtl ./results.jtl 2>/dev/null || true
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
