# Scale up all deployments in the upf namespace
for deployment in $(kubectl get deployments -n upf -o jsonpath='{.items[*].metadata.name}'); do
  kubectl scale deployment $deployment --replicas=3 -n upf
done

# Scale down all deployments in the upf namespace
for deployment in $(kubectl get deployments -n upf -o jsonpath='{.items[*].metadata.name}'); do
  kubectl scale deployment $deployment --replicas=1 -n upf
done

