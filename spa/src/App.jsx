import React, { useState, useEffect } from 'react'
import './App.css'
import NavBar from './components/NavBar.jsx';
import Search from './components/Search.jsx';
import Footer from './components/Footer.jsx';
import DataCardGrid from './components/DataCardGrid.jsx';

function App() {
  const [searchResult, setSearchResult] = useState('');
  const [searchQuery, setSearchQuery] = useState('');
  let url = `https://tw4alpb6lhcvg-container-app.happyflower-da7032d6.eastasia.azurecontainerapps.io/products?query=${searchQuery}`

  const childToParent = (childData) => {
    setSearchQuery(childData);
  }

  useEffect(() => {
    getData(searchQuery, url);
  }, [searchQuery]);

  const getData = async (searchQuery, url) => {
    if (searchQuery.length > 0) {
      try {
        console.log(searchQuery)
        console.log("url: " + url)
        const res = await fetch(url, { method: "GET", headers: { Accept: 'application/json', 'Content-Type': 'application/json' } });
        const jsonData = await res.json();
        if (res.status === 200) {
          console.log("got data: " + JSON.stringify(jsonData))
          setSearchResult(jsonData);
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
    <div class="main">
      <NavBar>
        <Search childToParent={childToParent} />
      </NavBar>
      <div class="h-screen content-center p-5 flex bg-slate-300 justify-center justify-items-center">
        <div class="flex-row pt-5">
          {searchResult.length > 0 &&
            <DataCardGrid data={searchResult} class="flex justify-center" />
          }
        </div>
      </div>
      <Footer />
    </div>
  )
}

export default App