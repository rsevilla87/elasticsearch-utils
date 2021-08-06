#!/bin/bash -e
# ElasticSearch opendistro ISM setup
# First argument is the index name

usage(){
  cat << EOF
Invocation error, usage:
$0 <ES_INSTANCE> <ES_INDEX> <DATE_FIELD>
EOF
  exit 1
}

if [[ ${#} -ne 3 ]]; then
  usage
fi
ES_SERVER=$1
INDEX=$2
DATE_FIELD=$3

# Create template with the desired ISM policy
TEMPLATE='{
  "index_patterns": ["'${INDEX}'-*"],
  "template": {
    "settings": {
      "opendistro.index_state_management.rollover_alias": "'${INDEX}'",
      "number_of_replicas": 0
    },
    "mappings": {
      "properties": {
        "'${DATE_FIELD}'": {
          "type": "date"
        }
      }
    }
  }
}'
echo ${TEMPLATE} | jq .
read -p "Hit enter to create the previous _index_template"
echo "Creating template ${INDEX}"
echo ${TEMPLATE} | curl -sS -X PUT ${ES_SERVER}/_index_template/${INDEX} -H "Content-type: application/json" -d@-

read -p "Hit enter to reindex"
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

read -p "Hit enter to delete original index"
# Delete original index
echo "Deleting ${INDEX}"
curl -sS -X DELETE ${ES_SERVER}/${INDEX}

read -p "Hit enter to create alias"
# Create alias
echo "Creating alias ${INDEX} for ${INDEX}-000001"
curl -sS -X POST ${ES_SERVER}/_aliases -H "Content-type: application/json" -d '{
  "actions" : [
    { "add" : { "index" : "'${INDEX}'-000001", "alias" : "'${INDEX}'"}}
  ]
}'

