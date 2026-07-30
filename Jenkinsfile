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
                    sleep 5
                    MASTER_POD=$(kubectl get pods -l app=jmeter-master -o jsonpath={.items[0].metadata.name})
                    echo "Master Pod is: $MASTER_POD"
         
                    # 3. Test khatam hone ka wait karein. (Jmeter test khatam karega, file banayega, tabhi sleep 60 shuru hoga)
                    echo "Waiting for Jmeter load test to finish..."
                    
                    # 4. Hum pod ke zinda rehte (sleep 60 ke dauran) file copy kar lenge
                    while kubectl get pod $MASTER_POD | grep -q "Running"; do
                        # Check agar JMeter ne file properly likh di hai
                        if kubectl exec $MASTER_POD -- test -s /results/results.jtl 2>/dev/null; then
                            echo "✅ Results file found! Copying..."
                            kubectl cp $MASTER_POD:/results/results.jtl ./results.jtl
                            break
                        fi
                        sleep 5
                    done
         
                    # Agar abhi bhi koi issue aata hai, toh galti JMeter logs mein dikhegi
                    if [ ! -s ./results.jtl ]; then
                        echo "❌ JMeter failed to create file! Printing logs to see what happened:"
                        kubectl logs $MASTER_POD
                        exit 1
                    fi
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
