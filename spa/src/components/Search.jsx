import React, { useState, useRef } from 'react';

export default function Search({ childToParentSearchQuery, childToParentTopResults }) {
    const [text, setText] = useState('');
    const [topResult, setTopResult] = useState(10);

    return (
        <div>
            <span class="">Search</span>
            <div class="inline-flex float-left">
                <div class="absolute inset-y-0 start-0 flex items-center ps-3 pointer-events-auto ">
                    <button
                        type="button"
                        class="w-4 h-4"
                        onClick={() => { childToParentSearchQuery(text); childToParentTopResults(topResult); setText('') }}
                    >
                        <div class="bg-[url('search-icon.png')] bg-cover w-4 h-4 opacity-45 hover:opacity-100"></div>
                    </button>
                    <span class="sr-only">Search icon</span>
                </div>
                <input id="searchInput" class="block w-full p-2 ps-10 text-sm text-gray-900 border border-gray-300 rounded-md bg-gray-50 focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
                    value={text}
                    type="text"
                    onChange={(event) => setText(event.target.value)}
                    placeholder="Type your query..."
                />
                <select class="bg-gray-50 border ml-2 p-2 border-gray-300 text-gray-900 text-sm rounded-md focus:ring-blue-500 focus:border-blue-500 block dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500" name="topResults" onChange={(event) => setTopResult(event.target.value)}>
                    <option value={10} defaultValue={10}>10</option>
                    <option value={20}>20</option>
                    <option value={50}>50</option>
                    <option value={100}>100</option>
                </select>
            </div>
        </div>
    )
}