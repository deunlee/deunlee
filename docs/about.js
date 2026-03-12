// https://carbon.now.sh/

function about()
{
    let name   = 'DeunLee';
  
    let id     = name.toLowerCase();
  
    let email  = id + '@' + id + '.com';
 
    let pgp    = '7a00 2df6 dcfa d44e d42f f698 1fd6 6407 ffa1 404a';

    let github = 'https://github.com/' + id;
  
    let likes  = ['javascript', 'typescript', 'python', 'rust'];
  
    return { name, id, email, pgp, github, likes };
}

console.log(about());
