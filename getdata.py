import requests
import json

key = "your_key"

def get_data():
  
  url = "https://acris-test.aalto.fi/ws/api/515/research-outputs?apiKey=" + key
  
  payload = {
    "size": 10, 
    "publishedAfterDate": "2019-09-01", 
    "publishedBeforeDate": "2019-08-15",
    "fields": ["title.value","electronicVersions.doi","publicationStatuses.current","publicationStatuses.publicationDate.year",
              "managingOrganisationalUnit.externalId", "managingOrganisationalUnit.name.text.value"],
    "locales": ["en_GB"],
    "publicationStatuses": ["/dk/atira/pure/researchoutput/status/published"],
    "typeUris": ["/dk/atira/pure/researchoutput/researchoutputtypes/contributiontojournal/article"],
    "publicationCategories": ["/dk/atira/pure/researchoutput/category/scientific"]
    }
            
  header = {"Accept": "application/json"} 
  
  response_decoded_json = requests.post(url, json=payload, headers=header)
  
  response_json = response_decoded_json.json()
  return response_json
