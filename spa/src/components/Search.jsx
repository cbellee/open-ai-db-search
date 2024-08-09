import React, { useState } from 'react';

export default function Search({ childToParent }) {
    const [text, setText] = useState();

    return (
        <div class="inline-flex float-left">
            <div class="absolute inset-y-0 start-0 flex items-center ps-3 pointer-events-auto">
                <button type="button" class="w-4 h-4" onClick={() => childToParent(text)}>
                    <img src='./search-icon.png' class="object-contain"></img>
                </button>
                <span class="sr-only">Search icon</span>
            </div>
            <input class="block w-full p-2 ps-10 text-sm text-gray-900 border border-gray-300 rounded-lg bg-gray-50 focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:border-gray-600 dark:placeholder-gray-400 dark:text-white dark:focus:ring-blue-500 dark:focus:border-blue-500"
                value={text}
                type="text"
                onChange={(e) => setText(e.target.value)}
                placeholder="Type your AI Search query..."
            />
        </div>
    )
}