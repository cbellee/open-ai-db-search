import React, { useState, useEffect } from 'react'
import './App.css'
import NavBar from './components/NavBar.jsx';
import Search from './components/Search.jsx';
import Footer from './components/Footer.jsx';
import DataCardGrid from './components/DataCardGrid.jsx';
import * as _ from 'lodash';

function App() {
  const [searchResult, setSearchResult] = useState('');
  const [searchQuery, setSearchQuery] = useState('all');
  const [topResults, setTopResults] = useState('10');

  let url = `${import.meta.env.VITE_API_URI}?query=${searchQuery}&top=${topResults}`

  const childToParentSearchQuery = (childData) => {
    setSearchQuery(childData);
  }

  const childToParentTopResults = (childData) => {
    setTopResults(childData);
  }

  useEffect(() => {
    getData(searchQuery, url);
  });

  const getData = async (searchQuery, url) => {
    if (searchQuery.length > 0) {
      try {
        const res = await fetch(url, { method: "GET", headers: { Accept: 'application/json', 'Content-Type': 'application/json' } });
        const jsonData = await res.json();
        if (res.status === 200) {
          setSearchResult(jsonData);
          setSearchQuery('');
        } else {
          console.log("an error occurred")
          setMessage("An error occurred")
        }
        setSearchQuery('');
      } catch (err) {
        console.log("error: " + err);
      }
    }
    setSearchQuery('');
  };

  return (
    <body class="flex flex-col min-h-screen">
      <main class="bg-slate-700 flex-grow">
        <div class="flex justify-center max-w-screen-2xl flex-col mx-auto">
          <NavBar>
            <Search childToParentSearchQuery={childToParentSearchQuery} childToParentTopResults={childToParentTopResults} />
          </NavBar>
          <div class="content-center min-h-screen p-5 flex bg-slate-200 justify-center justify-items-center">
            <div class="flex-row pt-5">
              {searchResult.length > 0 &&
                <DataCardGrid data={searchResult} class="flex justify-center" />
              }
            </div>
          </div>
          <Footer />
        </div>
      </main>
    </body>
  )
}

export default App