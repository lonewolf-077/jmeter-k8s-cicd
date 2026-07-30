pipeline {
    agent any
    stages {
        stage('1. Push Script to Kubernetes') {
            steps {
                // Aapke JMX file ko Kubernetes ka ConfigMap bana deta hai taaki image dobara na banani pade
                sh 'kubectl create configmap jmeter-script-config --from-file=test-script.jmx --dry-run=client -o yaml | kubectl apply -f -'
            }
        }
        stage('2. Start & Scale Workers') {
            steps {
                // Workers ko Kubernetes mein deploy karna
                sh 'kubectl apply -f worker.yaml'
                // Workers ki sankhya set karna (jaise 3 ya 5)
                sh 'kubectl scale deployment jmeter-worker --replicas=3'
                // Jab tak workers poori tarah ready na ho jayein, tab tak intezaar karna
                sh 'kubectl rollout status deployment/jmeter-worker'
            }
        }
        stage('3. Run Load Test (Master)') {
            steps {
                // Master ko start karna jo workers ko command dega
                sh '''
                    # 1. Master job apply karein
                    kubectl apply -f master.yaml
        
                    # 2. Thoda wait karein taaki pod running state mein aa jaye
                    echo "Waiting for master pod to start..."
                    sleep 5
        
                    # 3. Running master pod ka naam nikal lein
                    MASTER_POD=$(kubectl get pods -l app=jmeter-master --field-selector=status.phase=Running -o jsonpath={.items[0].metadata.name})
                    
                    # Agar pod turant complete ho jata hai toh saare pods me se pehla wala uthane ke liye:
                    if [ -z "$MASTER_POD" ]; then
                        MASTER_POD=$(kubectl get pods -l app=jmeter-master -o jsonpath={.items[0].metadata.name})
                    fi
        
                    echo "Master Pod is: $MASTER_POD"
        
                    # 4. Job ke complete hone ka wait karein
                    kubectl wait --for=condition=complete job/jmeter-master --timeout=600s || true
        
                    # 5. Job khatam hone se pehle ya logs/tar ke zariye result nikalne ke liye agar kubectl cp fail ho, 
                    # toh hum direct container ke logs ya ephemeral storage use kar sakte hain, 
                    # par agar kubectl cp chalana hai toh job complete hone se pehle background me loop chala sakte hain.
                '''
                // Test complete hone ka wait karna (max 10 minutes)
                sh '''
                    MASTER_POD=$(kubectl get pods -l app=jmeter-master -o jsonpath={.items[0].metadata.name})
                    kubectl cp ${MASTER_POD}:/results/results.jtl ./results.jtl || echo "Copy failed, trying alternative..."
                '''
            }
        }
    }
    post {
        always {
            // Step 5: Test khatam hone ke baad cloud resources ko delete karna taaki paisa na lage
            sh 'kubectl delete -f master.yaml || true'
            sh 'kubectl delete -f worker.yaml || true'
            // Jenkins dashboard par performance graph dikhana
            perfReport 'results.jtl' 
        }
    }
}
