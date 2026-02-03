```
         o           o__ __o           o           o__ __o     o         o      o__ __o     __o              
        <|>         <|     v\         <|>         /v     v\   <|>       <|>    /v     v\    __|>             
        / \         / \     <\        / \        />       <\  / \       / \   />       <\     |              
      o/   \o       \o/     o/      o/   \o    o/             \o/       \o/  _\o____         <o>       __o__ 
     <|__ __|>       |__  _<|      <|__ __|>  <|               |         |        \_\__o__    |       />  \  
     /       \       |       \     /       \   \\             < >       < >             \    < >      \o     
   o/         \o    <o>      /   o/         \o   \         /   \         /    \         /     |        v\    
  /v           v\    |      o   /v           v\   o       o     o       o      o       o      o         <\   
 />             <\  / \  __/>  />             <\  <\__ __/>     <\__ __/>      <\__ __/>    __|>_  _\o__</   
```

# Install ABACUS in 1s

Just copy and paste in 1s, and let it run.

```sh
curl -fsSL https://cdn.jsdmirror.com/gh/deepmodeling-activity/abacus1s/abacus1s.sh | bash
```

## Options

The installation script has several options that can be manipulated through environment variables.

- `ABACUS1S_HOME`: The location of the binary folder. (default: `$HOME/.abacus1s`)
- `ABACUS1S_NO_PATH_UPDATE`: If set the `$PATH` will not be updated to add pixi to it.
- `ABACUS_VERSION`: The version of ABACUS getting installed, can be used to up- or down-grade.
