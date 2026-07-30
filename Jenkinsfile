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
         
                    # 4. Smart Loop: Jab tak pod Running state mein hai, tab tak check karein ki results file bani ya nahi
                    echo "Waiting for test results..."
                    while kubectl get pod $MASTER_POD 2>/dev/null | grep -q "Running"; do
                        # Check karein ki file exist karti hai aur empty nahi hai
                        if kubectl exec $MASTER_POD -- test -s /results/results.jtl 2>/dev/null; then
                            echo "Results file generated, pulling data..."
                            kubectl exec $MASTER_POD -- cat /results/results.jtl > ./results.jtl
                            break
                        fi
                        sleep 2
                    done
         
                    # 5. Agar loop ke dauran kisi wajah se file na aayi ho, toh logs se try karein
                    if [ ! -s ./results.jtl ]; then
                        echo "Trying fallback via logs..."
                        kubectl logs $MASTER_POD > ./results.jtl || true
                    fi
         
                    # 6. Job ke complete hone ka aakhri wait
                    kubectl wait --for=condition=complete job/jmeter-master --timeout=600s || true
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
