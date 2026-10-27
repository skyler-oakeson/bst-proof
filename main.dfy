datatype BSTree = Leaf | Node(data: int, left: BSTree, right: BSTree)
datatype Result<T> = Ok(v: T) | Err(e: string)

predicate Contains(x: int, t: BSTree) 

{
    match t {
        case Node(v, left, right) =>
            if x == v then true
            else if x > v then Contains(x, right)
            else Contains(x, left)
        case Leaf => false
    }
}

function Size(t: BSTree): nat
{
    match t
        case Node(v, left, right) => 1 + Size(left) + Size(right)
        case Leaf => 0
}

function Elements(t: BSTree): set<int> 
{
    match t
    case Leaf => {}
    case Node(v, l, r) => Elements(l) + {v} + Elements(r)
}

// Ensures that the tree is in a valid ordering and that there is no duplicate entries
predicate Valid(t: BSTree)
{
    if t.Leaf? then 
        true
    else
    
    match t {
        case Node(v, left, right) => 
            (forall d :: d in Elements(left) ==> v > d) &&
            (forall d :: d in Elements(right) ==> v < d) &&
            Valid(left) && Valid(right)
        case Leaf => true
    }
}

function Push(x: int, t: BSTree): (m: BSTree)
requires Valid(t)
ensures Size(t) <= Size(m)
ensures Elements(Push(x, t)) == Elements(t) + {x}
ensures Valid(m)
decreases t
{
    match t {
        case Node(v, left, right) =>
            if v < x then Node(v, left, Push(x, right))
            else if v > x then Node(v, Push(x, left), right)
            else t
        case Leaf => Node(x, Leaf, Leaf)
    }
}


function FindAndReturn(x: int, t: BSTree): (m: Result<int>) 
requires Valid(t)
ensures match m {
    case Ok(v) => v == x
    case Err(_) => !(x in Elements(t))
}
ensures Valid(t)
decreases t
{
    match t {
        case Node(v, left, right) =>
            if x == v then Ok(v)
            else if x > v then FindAndReturn(x, right)
            else FindAndReturn(x, left)
        case Leaf => Err("Error: Value not found.")
    }
}

function Remove(x: int, t: BSTree): (m: BSTree)
requires Valid(t)
ensures Size(t) >= Size(m)
ensures Elements(Remove(x, t)) == Elements(t) - {x}
decreases t
{
    if t.Leaf? then
        Leaf
    else

    var v, left, right := t.data, t.left, t.right;
    if v == x then
        match t {
            // no children deletion
            case Node(_, Leaf, Leaf) => Leaf
            // one child left deletion
            case Node(_, left, Leaf) => left
            // one child right deletion
            case Node(_, Leaf, right) => right
            // two children deletion
            case Node(_, left, right) =>
                // find the smallest of the right subtree to be the replacement node
                // remove it from the subtree

                // note: this was unable to be proved because it wasn't able to prove
                // q existed in the elements of t. Strengthened with the post condition in
                // LeastOfTree to fix it.
                match LeastOfTree(right)
                    case Node(q, _, _) =>
                        Node(q, left, Remove(q, right))
        }
    else if x > v then
        Node(v, left, Remove(x, right))
    else
        Node(v, Remove(x, left), right)
}


// returns the least node on a given BSTree
function LeastOfTree(t: BSTree): (m: BSTree)
requires Valid(t)
ensures t.Node? ==> m.Node?
ensures t.Node? && m.Node? ==> t.data >= m.data
ensures m.Node? ==> m.left == Leaf
ensures m.Node? ==> m.data in Elements(t)
ensures Valid(m)
{
    match t {
        case Node(v, Leaf, _) => t
        case Node(v, left, _) => LeastOfTree(left)
        case Leaf => Leaf
    }
}

method Main() 
{
    var t := Leaf;
    t := Push(10, t);
    t := Push(2, t);
    t := Push(100, t);
    t := Push(76, t);
    t := Push(110, t);
    t := Push(105, t);
    t := Push(130, t);
    t := Push(140, t);
    t := Push(106, t);
    t := Push(106, t);

    print t;
    print "\n";

    t := Remove(110, t);


    print t;

    // var res2 := FindAndReturn(6, t);
    // match res {
    //     case Ok(v) => print v;
    //     case Err(e) => print e;
    // }
}