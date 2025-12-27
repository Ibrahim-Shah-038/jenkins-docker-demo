import jenkins.model.*
import hudson.model.*
import hudson.slaves.*

// Usage: paste in Script Console or run as an init script (init.groovy.d) to create the node and print the JNLP secret

def name = 'docker-agent'

def jenkins = Jenkins.getInstance()

def node = jenkins.getNode(name)
if (node == null) {
  println("Creating node: ${name}")
  def launcher = new JNLPLauncher()
  def newNode = new DumbSlave(name, 'Auto-created docker agent', '/home/jenkins', '2', Node.Mode.NORMAL, 'docker', launcher, RetentionStrategy.INSTANCE, [])
  jenkins.addNode(newNode)
  node = jenkins.getNode(name)
  println("Node created")
} else {
  println("Node already exists: ${name}")
}

def computer = node.toComputer()
if (computer == null) {
  println("Node computer not available yet. Ensure Jenkins has reloaded configuration.")
} else {
  def secret = computer.getJnlpMac()
  println("JNLP secret for ${name}: ${secret}")
}
