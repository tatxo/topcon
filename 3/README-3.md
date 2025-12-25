# Monitoring test

There are multiple solutions to achieve this, including propietary New Relic, Datadog or Dynatrace, however in the Open Source range, I have chosen two: 

* Netdata, the simplest way to complete this challenge.
* Prometheus+Grafana, the industry standard.

To simplify this test, I am going to monitor my own laptop, currently is running ubuntu 22.04 LTS.  Same code can be tested in a EC2 instance with access to port 19999.

## Netdata

* Install Netdata:

```
wget -O /tmp/netdata-kickstart.sh https://get.netdata.cloud/kickstart.sh && sh /tmp/netdata-kickstart.sh
```
* Access the dashboard with a browser:
`http://localhost:19999` 

* Click on "Skip and browse anonymously"
* Enjoy!

## Prometheus + Grafana

There are many options for this challenge, one used often consists in using helm to install the stack Kubernetes, however as I don't have a running kubernetes cluster at the moment, I am opting for other options.

For this setup, I am assuming we have an EC2 instance already created with Terraform running ubuntu 22.04 LTS, in my case I am going to use a home server running ubuntu 22.04 LTS (192.168.1.49) instead.  I will run the configuration using Ansible in my MacOS.  

In the real word we can execute the terraform code from a pipeline and after success and test the readiness of the instance, to run ansible for the configuration part of the instance.  Another option could be to use bash in the userdata of the EC2 instace, however I consider Ansible could eventually be a better option as it allows to maintain changes in a 24/7 running instance configuration while in production.

##### Ensure ansible is installed

```
$ ansible --version | head -1
ansible [core 2.20.1]
```

##### Run the automation

```
ansible-playbook -i 192.168.1.49, test-3.yml
```
##### Manual steps

* Open grafana in a browser 
`http://192.168.1.49:3000`  
Default user:password is `admin:admin`, it will prompt to change it.
* Connect Grafana to Prometheus
    * In _Conections>Data Sources_ click _Add data source_ and select _Prometheus_ 
    * In the URL field, enter `http://localhost:9090`
    * Scroll down and click _Save & Test_
* Import a dashboard
    * Click in the + icon in the top right > _Import_
    * In the "Import via grafana.com" field, enter ID `1860` (Node Exporter Full)
    * Click _Import_

##### Considerations

* If prometheus-node-exporter is installed, Prometheus grabs the stats about the local machine by default, however I have overwritten the prometheus config with a local version.
* As ssh requires a valid ssh-key to connect to the server, using SSM in Ansible for an EC2 instance can be considered.
* Troubleshooting
    * You can check the node-exporter is working in `http://192.168.1.49:9100/metrics`
    * Check Prometheus is getting the metrics from the node-exporter: `http://192.168.1.49:9090/targets`. The state should be `UP`.
    * Adjust time range in Grafana. For a just installed stack, dashboard should be set from `Last 24 hours` to `Last 5 minutes`.
