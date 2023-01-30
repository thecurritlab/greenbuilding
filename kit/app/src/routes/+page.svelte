<script>
    /** @type {import('./$types').PageData} */
    export let data;
    console.log(data);
</script>

<h1>Welcome to SvelteKit</h1>
<p>Visit <a href="https://kit.svelte.dev">kit.svelte.dev</a> to read the documentation</p>

<h2>Car List</h2><small>(This comes from the API!)</small>
<ul>
    { #each data.items as car }
        <li>{ car.make } { car.model }: ${ car.price }</li>
    {/each}
</ul>
