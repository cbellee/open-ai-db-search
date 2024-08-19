import React, { useState, useEffect } from 'react'
import './App.css'
import NavBar from './components/NavBar.jsx';
import Search from './components/Search.jsx';
import Footer from './components/Footer.jsx';
import DataCardGrid from './components/DataCardGrid.jsx';
import usePagination from './components/Pagination.jsx';
import { Pagination } from '@mui/material';
import * as _ from 'lodash';

function App() {
  const [searchResult, setSearchResult] = useState('');
  const [searchQuery, setSearchQuery] = useState('shoes');
  const [cardsPerPage, setCardsPerPage] = useState('10');

  let url = `${import.meta.env.VITE_API_URI}?query=${searchQuery}`
  let [page, setPage] = useState(1);

  const count = Math.ceil(searchResult.length / cardsPerPage);
  const paginationData = usePagination(searchResult, cardsPerPage);

  const handlePageChange = (e, p) => {
    setPage(p);
    paginationData.jump(p);
  };

  const childToParentSearchQuery = (childData) => {
    setSearchQuery(childData);
    paginationData.jump(1);
    setPage(1);
  }

  const childToParentCardsPerPage = (childData) => {
    setCardsPerPage(childData);
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
    <body class="flex flex-col">
      <main class="bg-slate-700">
        <div class="flex justify-center max-w-screen-2xl flex-col mx-auto">
          <NavBar>
            <Search childToParentSearchQuery={childToParentSearchQuery} childToParentCardsPerPage={childToParentCardsPerPage} />
          </NavBar>
          <div class="min-h-screen p-5 flex-row bg-slate-200 ">
            {
              console.log("total items: " + searchResult.length)
            }
            <div class="flex pt-4 justify-center">
              <Pagination
                class={`${paginationData.currentData().length <= 0 ? `opacity-0` : `opacity-100`}`}
                count={count}
                size="large"
                page={page}
                variant="outlined"
                shape="rounded"
                onChange={handlePageChange}
              />
            </div>
            <div class="flex-row pt-5">
              {paginationData.currentData().length > 0 &&
                <DataCardGrid data={paginationData.currentData()} class="flex justify-center" />
              }
            </div>
            <div class="flex pt-4 justify-center">
              <Pagination
                class={`${paginationData.currentData().length <= 0 ? `opacity-0` : `opacity-100`}`}
                count={count}
                size="large"
                page={page}
                variant="outlined"
                shape="rounded"
                onChange={handlePageChange}
              />
            </div>
          </div>
          <Footer />
        </div>
      </main>
    </body>
  )
}

export default App