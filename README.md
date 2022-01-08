# If you want to run Julia from Python
1. Set up a Python env:

```shell
> cd jl2py/
> conda create --prefix envs python=3; conda activate envs
```

I'm setting it up in the same dir as this project because `juliacall` will automatically store the Julia environment
inside of it for us in the next step, and it's nice having everything be in one place:

2. Install `juliacall`:
```shell
> poetry install
```

3. Fire up a Python shell and create the local Julia environment:
```python
python> from juliacall import Main as jl
```

4. In another window, navigate to the automatically created Julia environment and start adding packages! (You can also
   do this directly from your Python shell, but using the Julia package manager directly is just so satisfying):

```shell
> cp Project.toml envs/julia_env/
> cd envs/julia_env/
> julia --project=.
> ] # Entering this key puts us into "package manager" mode
(julia_env) pkg> up
# Short for update
# It downloads the phonebook of available packages and enables some slick autocomplete
(julia_env) pkg> add <your julia packages here>
```

Similarly to `poetry`, you can skip this last step of manually adding packages if you already have your Julia packages
specified. This is given by the Project.toml, which we copied into this env for this repo.

5. Back in your Python shell, start calling some Julia code!
```python
python> x = jl.rand(3, 4)
python> x
3×4 Matrix{Float64}:
 0.184375  0.210192  0.416314  0.73652
 0.153468  0.100324  0.445996  0.749966
 0.751745  0.270303  0.282827  0.297428
```

Check out this
[notebook](https://nbviewer.org/github/icweaver/juliacall_example/blob/main/jl2py/notebook.ipynb?flush_cache=true) for an
example of how to start using Julia packages in a Python workflow.

# If you want to run Python from Julia
1. Open [this notebook](https://icweaver.github.io/juliacall_example/py2jl/notebook.jl.html)
2. Click on "Edit or run this notebook" in the top right
3. Follow the instructions to download and open the notebook with [Pluto.jl](https://github.com/fonsp/Pluto.jl)
4. That's it
