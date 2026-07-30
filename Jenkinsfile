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
                    # 1. Sabse pehle purani khali file delete karein taaki parse error na aaye
                    rm -f ./results.jtl || true
         
                    # 2. Master job apply karein
                    kubectl apply -f master.yaml
         
                    # 3. Pod ke active hone ka wait karein
                    sleep 5
                    MASTER_POD=$(kubectl get pods -l app=jmeter-master -o jsonpath={.items[0].metadata.name})
                    echo "Master Pod is: $MASTER_POD"
                    echo "Load Test chal raha hai... Please wait 🚀"
         
                    # 4. Smart Copy Loop: Test chalne ke dauran continuously file backup lete rahein
                    while true; do
                        PHASE=$(kubectl get pod $MASTER_POD -o jsonpath='{.status.phase}')
                        
                        # Har 5 second mein data copy karein (taki pod marne ka darr na rahe)
                        kubectl cp $MASTER_POD:/results/results.jtl ./results.jtl 2>/dev/null || true
                        
                        # Check karein agar test successfully khatam ho gaya
                        if kubectl logs $MASTER_POD 2>/dev/null | grep -q "end of run"; then
                            echo "✅ Test finished! Final copy in progress..."
                            kubectl cp $MASTER_POD:/results/results.jtl ./results.jtl 2>/dev/null || true
                            break
                        fi
                        
                        # Agar pod pehle hi mar gaya toh loop tod dein
                        if [ "$PHASE" = "Succeeded" ] || [ "$PHASE" = "Failed" ]; then
                            echo "Pod test complete kar chuka hai."
                            break
                        fi
                        
                        sleep 5
                    done
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
