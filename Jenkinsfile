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
                sh 'kubectl apply -f master.yaml'
                // Test complete hone ka wait karna (max 10 minutes)
                sh 'kubectl wait --for=condition=complete job/jmeter-master --timeout=600s'
            }
        }
        stage('4. Download Results') {
            steps {
                // Master pod se results.jtl file nikal kar Jenkins mein lana
                sh '''
                    # Master pod ka naam nikalein chahe woh running ho ya completed phase mein
                    MASTER_POD=$(kubectl get pods -l app=jmeter-master -o jsonpath={.items[0].metadata.name})
                    
                    # Agar pod completed hai, toh logs ya cp ke liye thoda dhyan dena padta hai, 
                    # ya aap job complete hone ki wait command ke baad direct copy chala sakte hain:
                    kubectl cp ${MASTER_POD}:/results/results.jtl ./results.jtl || true
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
