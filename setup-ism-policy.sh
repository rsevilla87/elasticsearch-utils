#!/bin/bash -e
# ElasticSearch opendistro ISM setup
# First argument is the index name

usage(){
  cat << EOF
Invocation error, usage:
$0 <ES_INSTANCE> <ES_INDEX> <POLICY>
EOF
  exit 1
}

if [[ ${#} -ne 3 ]]; then
  usage
fi
ES_SERVER=$1
INDEX=$2
POLICY=$3

# Create template with the desired ISM policy
echo "Creating template ${INDEX}"
curl -sS -X PUT ${ES_SERVER}/_template/${INDEX} -H "Content-type: application/json" -d '{
  "index_patterns": [
    "'${INDEX}'-*"
  ],
  "settings": {
    "opendistro.index_state_management.policy_id": "'${POLICY}'",
    "opendistro.index_state_management.rollover_alias": "'${INDEX}'",
    "index":{
      "number_of_replicas": 0
    }
  }
}'

# Reindex
echo "Reindexing ${INDEX} to ${INDEX}-000001"
curl -sS -X POST ${ES_SERVER}/_reindex -H "Content-type: application/json" -d '{
  "source": {
    "index": "'${INDEX}'"
  },
  "dest": {
    "index": "'${INDEX}'-000001"
  }
}'

# Delete original index
echo "Deleting ${INDEX}"
curl -sS -X DELETE ${ES_SERVER}/${INDEX}

# Create alias
echo "Creating alias ${INDEX} for ${INDEX}-000001"
curl -sS -X POST ${ES_SERVER}/_aliases -H "Content-type: application/json" -d '{
  "actions" : [
    { "add" : { "index" : "'${INDEX}'-000001", "alias" : "'${INDEX}'"}}
  ]
}'

