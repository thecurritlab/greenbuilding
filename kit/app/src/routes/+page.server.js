import { error } from '@sveltejs/kit';
import { API_KEY } from '$env/static/private';

const myHeaders = new Headers();
myHeaders.append("Authorization", "Bearer " + API_KEY);
console.log(API_KEY);
console.log(myHeaders);

const requestOptions = {
  method: 'GET',
  headers: myHeaders
};

/** @type {import('./$types').PageServerLoad} */
export async function load({ fetch, setHeaders }) {
    const url = `http://localhost:3000/cars`;
    const res = await fetch(url, requestOptions);
    const items = await res.json();
    // console.log(items);
    if (items) {
        return { items };
    }
    
    throw error(404, 'Not found');
}
