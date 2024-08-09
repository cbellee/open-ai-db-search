import React from 'react';
import { useEffect, useState } from 'react';
import DataCardGrid from './DataCardGrid';

function DataFetcher() {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [message, setMessage] = useState();
  const [queryText, setQueryText] = React.useState("");

  const handleSubmit = async (e) => {
    e.PreventDefault;
    if (queryText.length > 0) {
      try {
        console.log(e.target)
        let url = `https://tw4alpb6lhcvg-container-app.happyflower-da7032d6.eastasia.azurecontainerapps.io/products?query=${queryText}`
        console.log("url: " + url)
        const res = await fetch(url, { method: "GET", headers: { Accept: 'application/json', 'Content-Type': 'application/json' } });
        const jsonData = await res.json();
        if (res.status === 200) {
          console.log("got data: " + JSON.stringify(jsonData))
          setData(jsonData);
        } else {
          console.log("an error occurred")
          setMessage("An error occurred")
        }
      } catch (err) {
        console.log("error: " + err);
      }
    }
  };

  return (
    <main class="">
      <div class="flex-row">
        <form onSubmit={handleSubmit}>
          <div class="inline-flex float-left">
            <input class="bg-gray-100 outline outline-2 outline-gray-200 float-left mr-4 w-96 p-2"
              value={queryText}
              type="text"
              onChange={(e) => setQueryText(e.target.value)}
              placeholder="Type your query..."
            />
             <button type="button" class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-1 px-4 rounded float-left" onClick={handleSubmit}>Search</button>
          </div>
        </form>
        <div class="flex-row">
         
        </div>
        <div class="flex-row">
          {data.length > 0 &&
            <DataCardGrid data={data} class="flex justify-center" />
          }
        </div>
      </div>
    </main>
  );
};

export default DataFetcher;

