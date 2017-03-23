require! {
  lodash: _

  'react': {DOM}:react
  'react-dom'
  immutable: {Map, Set, List, fromJS}
  mathjs: math
  hammerjs: Hammer
}

__halfpi = Math.PI / 2

scale-to-r = (v, min, max) -> (v - min) / (max - min)
scale-from-r = (v, min, max) -> min + v * (max - min)
scale = (v, in-min, in-max, out-min, out-max) -> scale-to-r v, in-min, in-max |> scale-from-r _, out-min, out-max

create-object = (proto, def, constructor, destructor, {autobind}?) ->
  throw 'you can\'t declare `$destructor` manually' if def.$destructor?
  Object.create (proto ? {})
  |> ->
    &0 <<< def <<< $destructor: (destructor ? ->)
    if autobind
      for own key, value of &0
        &0[key] = Function::bind.call value, &0 if _.is-function value
    constructor?call &0
    &0

abstract-method = ->
  console.error 'pure virtual function call'
  console.trace!

Easing = _.assign do
  # https://gist.github.com/gre/1650294

  # no easing, no acceleration
  linear: -> it

  # in - accelerating from zero velocity
  # out - decelerating to zero velocity
  # in-out - acceleration until halfway, then deceleration

  ease-in-quad: (t, b, c, d) -> b + c * (t /= d) * t
  ease-out-quad: (t, b, c, d) -> b - c * (t /= d) * (t - 2)
  ease-in-out-quad: (t, b, c, d) ->
    | (t /= d / 2) < 1 => b + c / 2 * t * t
    | _ => b - c / 2 * ((--t) * (t - 2) - 1)
  ease-in-cubic: (t, b, c, d) -> b + c * (t /= d) * t * t
  ease-out-cubic: (t, b, c, d) -> b + c * ((t = t / d - 1) * t * t + 1)
  ease-in-out-cubic: (t, b, c, d) ->
    | (t /= d / 2) < 1 => b + c / 2 * t * t * t
    | _ => b + c / 2 * ((t -= 2) * t * t + 2)
  ease-in-quart: (t, b, c, d) -> b + c * (t /= d) * t * t * t
  ease-out-quart: (t, b, c, d) -> b - c * ((t = t / d - 1) * t * t * t - 1)
  ease-in-out-quart: (t, b, c, d) ->
    | (t /= d / 2) < 1 => b + c / 2 * t * t * t * t
    | _ => b - c / 2 * ((t -= 2) * t * t * t - 2)
  ease-in-quint: (t, b, c, d) -> b + c * (t /= d) * t * t *t * t
  ease-out-quint: (t, b, c, d) -> b + c * ((t = t / d - 1) * t * t * t * t + 1)
  ease-in-out-quint: (t, b, c, d) ->
    | (t /= d / 2) < 1 => b + c / 2 * t * t * t * t * t
    | _ => b + c / 2 * ((t -= 2) * t * t * t * t + 2)
  ease-in-sine: (t, b, c, d) -> c + b - c * Math.cos (t / d * __halfpi)
  ease-out-sine: (t, b, c, d) -> b + c * Math.sin (t / d * __halfpi)
  ease-in-out-sine: (t, b, c, d) -> b - c / 2 * ((Math.cos Math.PI * t / d) - 1)
  ease-in-expo: (t, b, c, d) -> b + c * Math.pow 2, 10 * (t / d - 1)
  ease-out-expo: (t, b, c, d) -> if t == d => b + c else (b + c * (1 - (Math.pow 2, -10 * t / d)))
  ease-in-out-expo: (t, b, c, d) ->
    | t == 0 => b
    | t == d => b + c
    | ((t /= d / 2) < 1) => b + c / 2 * (Math.pow 2, 10 * (t - 1))
    | _ => b + c / 2 * (2 - (Math.pow 2, -10 * --t))
  ease-in-circ: (t, b, c, d) -> b - c * ((Math.sqrt 1 - (t /= d) * t) - 1)
  ease-out-circ: (t, b, c, d) -> b + c * (Math.sqrt 1 - (t = t / d - 1) * t)
  ease-in-out-circ: (t, b, c, d) ->
    | ((t /= d / 2) < 1) => b - c/2 * ((Math.sqrt 1 - t * t) - 1)
    | _ => b + c/2 * ((Math.sqrt 1 - (t -= 2) * t) + 1)
  # ease-in-elastic: (t, b, c, d) ->
  #   var s=1.70158;
  #   if (t==0) return b;
  #   if ((t/=d)==1) return b+c;
  #   var p = d * 0.3
  #   var a = c;
  #   if (a < Math.abs(c)) {
  #     var s=p/4;
  #   }
  #   else
  #     var s = p/(2*Math.PI) * Math.asin (c/a)
  #   return -(a*Math.pow(2,10*(t-=1)) * Math.sin( (t*d-s)*(2*Math.PI)/p )) + b
  # },
  # easeOutElastic: function (x, t, b, c, d) {
  #   var s=1.70158;var p=0;var a=c;
  #   if (t==0) return b;  if ((t/=d)==1) return b+c;  if (!p) p=d*.3;
  #   if (a < Math.abs(c)) { a=c; var s=p/4; }
  #   else var s = p/(2*Math.PI) * Math.asin (c/a);
  #   return a*Math.pow(2,-10*t) * Math.sin( (t*d-s)*(2*Math.PI)/p ) + c + b;
  # },
  # easeInOutElastic: function (x, t, b, c, d) {
  #   var s=1.70158;var p=0;var a=c;
  #   if (t==0) return b;  if ((t/=d/2)==2) return b+c;  if (!p) p=d*(.3*1.5);
  #   if (a < Math.abs(c)) { a=c; var s=p/4; }
  #   else var s = p/(2*Math.PI) * Math.asin (c/a);
  #   if (t < 1) return -.5*(a*Math.pow(2,10*(t-=1)) * Math.sin( (t*d-s)*(2*Math.PI)/p )) + b;
  #   return a*Math.pow(2,-10*(t-=1)) * Math.sin( (t*d-s)*(2*Math.PI)/p )*.5 + c + b;
  # },
  ease-in-back: (t, b, c, d, s ? 1.70158) -> b + c * (t /= d) * t * ((s + 1) * t - s)
  ease-out-back: (t, b, c, d, s ? 1.70158) -> b + c * ((t = t / d - 1) * t * ((s + 1) * t + s) + 1)
  ease-in-out-back: (t, b, c, d, s ? 1.70158) ->
    | (t /= d / 2) < 1 => b + c / 2 * (t * t * (((s *= 1.525) + 1) * t - s))
    | _ => b + c / 2 * ((t -= 2) * t * (((s *= 1.525) + 1) * t + s) + 2)
  ease-in-bounce: (t, b, c, d) -> b + c - (Easing.ease-out-bounce (d - t), 0, c, d)
  ease-out-bounce: (t, b, c, d) ->
    | (t /= d) < (1 / 2.75) => b + c * (7.5625 * t * t)
    | t < (2 / 2.75) => b + c * (7.5625 * (t -= (1.5 / 2.75)) * t + 0.75)
    | t < (2.5 / 2.75) => b + c * (7.5625 * (t -= (2.25 / 2.75)) * t + 0.9375)
    | _ => b + c * (7.5625 * (t -= (2.625 / 2.75)) * t + 0.984375)
  ease-in-out-bounce: (t, b, c, d) ->
    | t < (d / 2) => b + 0.5 * Easing.ease-in-bounce (t * 2), 0, c, d
    | _ => c * 0.5 + b + 0.5 * Easing.ease-out-bounce (t * 2 - d), 0, c, d

lerp = (v0, v1, t) -> v0 + t * (v1 - v0)

BezierLutFabric = (steps, [x0, y0, xc, yc, x1, y1]) -> create-object do
  {}
  (x, b, c, d) ->
    | (v0 = math.floor (d = scale x, 0, d, 0, @lut.length)) < 0 => @lut.0
    | (v1 = v0 + 1) >= @lut.length => @lut[* - 1]
    | _ => b + c * lerp @lut[v0], @lut[v1], (d - v0)
  ->
    @lut = new bezierjs.Bezier x0, y0, xc, yc, x1, y1 .get-LUT!

State = (key, from, to, duration, easing, ended) -> create-object do
  {}
  {
    key
    ended
    from
    easing
    dv: to - from
    d: duration

    get: (ts) ->
      @start-ts ?= ts
      dt = ts - @start-ts
      if @d <= dt
        @ended @
        @from + @dv
      else
        @easing dt, @from, @dv, @d
          # console.log @easing, dt, @d, @from, @dv, '=>', ..
    clone: (reverse) ->
      f = @from
      t = f + @dv
      [f, t] = [t, f] if reverse
      State @key, f, t, @d, @easing, @ended
  }
  ->
  ->

Animation = (did-ended, id, node, transitions, {easing, duration, repeat, repeat-bounce}) -> create-object do
  {}
  {
    id
    node
    easing
    duration
    repeat: math.max 0, +repeat
    did-ended
    repeat-bounce

    repeat-cycle: 0
    repeat-cycle-direction: true
    current: (ts) -> [
      @node
      _.map-values @states, (.get ts)
    ]
  }
  ->
    @states =
      _ transitions
      .map-values (definition, key) ~>
        switch
        | _.is-array definition
          make-state = (key, start, next, duration, rest) ~>
            State key, start, next, duration, @easing, (.bind @, next, rest) (start, rest, state) ~>
              key = state.key
              delete @states[key]
              if rest?
                [next, ...rest] = rest
                rest = null unless rest.length > 0
                @states[key] = (make-state key, start, next, duration, rest)
              if 1 > _.size @states
                if ++@repeat-cycle < @repeat
                  @states = @origin-states
                  @origin-states = _.map-values @states, (.clone @repeat-bounce)
                else
                  @did-ended!

          [start, next, ...rest] = definition
          rest = null unless rest.length > 0
          (make-state key, start, next, @duration, rest)
        | "_" => console.log \unimplemented; null
      .pick-by (?)
      .value!

    if @repeat > 0 # positive number, not nan
      @origin-states = _.map-values @states, (.clone @repeat-bounce)

Constants = (init ? {}) ->
  with {}
    o = ..
    o.__dont-touch-this__values = {}
    o.add = (.bind o) (name, value) ->
      @__dont-touch-this__values[name] = value
      Object.define-property @, name, do
        value: value
        writable: false
        configurable: false
      @
    
    _.for-each init, !~> o.add &1, &0

# constants = Constants do
#   c1: 2
#   c3: 4

# console.log constants.c1
# console.log constants.c1

GetBezierPoint = (t, controlPoints, index, count) ->
  return controlPoints[index] if count == 1
  P0 = GetBezierPoint t, controlPoints, index, count - 1
  P1 = GetBezierPoint t, controlPoints, index + 1, count - 1
  [(1 - t) * P0.0 + t * P1.0, (1 - t) * P0.1 + t * P1.1]

GetBezierApproximation = (controlPoints, outputSegmentCount) ->
  console.log control-points
  [GetBezierPoint (i / outputSegmentCount), controlPoints, 0, controlPoints.length for i from 0 to outputSegmentCount]

Observable =
  init-observable: ->
    @_observable-observers = Map!as-mutable!
    @_observable-uid = 0

  sub: ->
    while @_observable-observers.has (id = (@_observable-uid = ++@_observable-uid % Number.MAX_SAFE_INTEGER)) =>
    @_observable-observers.set id, &0
    (.bind @, id) (id) !-> @_observable-observers.remove id

  notify-all-observers: -> @_observable-observers.for-each (.bind null, &) (...) -> it.call null, &0

normalize-float-for-css = ->
  math.round do
    if 0.1e-4 > Math.abs it => 0 else it
    4

prepare-style-numeric = (def, allowed-types) ->
  (.bind null, def, allowed-types) (def, allowed-types, v) ->
    | not _.is-NaN (v2 = +v) # number or 'number'
      "#{normalize-float-for-css v2}#{if def.number-to-pixel => 'px' else ''}" 
    | _.is-string v
      unless _.some <[px em rem]>, (-> v.ends-with it)
        throw "unknown value for #{v}"
    | _ => throw '??? r2r2e2r ' + v

known-styles =
  left: prepare-style-numeric number-to-pixel: true

set-style = (node, style) ->
  styles = {}
  _.for-each style, ->
    unless (p = known-styles[&1])?
      throw '??? khgjh'
    try
      if (p &0)?
        styles[&1] = that
    catch e
      console.error e
  if Object.keys styles .length
    node.style <<< styles

Insanimate = -> create-object do
  {}
  animations: Map!as-mutable!
  uid: 0
  _raf-in-loop: false
  animation-did-end: (id) ->
    @animations .= remove id
    @raf-in-loop = false if @animations.size < 1

  raf: (ts) !->
    @raf-id = null
    return unless @_raf-in-loop
    @raf-id ?= request-animation-frame @raf

    @animations.as-immutable!value-seq!map (.current ts) .for-each (q) !~>
      return unless q?
      [node, style] = q
      set-style node, style
    
  animate: (n, d, o) ->
    while (@animations.get (id = ++@uid % Number.MAX_SAFE_INTEGER))? =>
    @animations .= set id, Animation (@animation-did-end.bind @, id), id, n, d, o
    @raf-in-loop = true
  
  ->
    Object.define-property @, \rafInLoop,
      set: !->
        @raf-id ?= request-animation-frame @~raf if (@_raf-in-loop != &0) and (@_raf-in-loop = &0)
      get: -> @_raf-in-loop
  ->
    @raf-in-loop = false

  autobind: true

insanimate = Insanimate!

h-flex-box = ->
  display: \flex
  flex-direction: \row

v-flex-box = ->
  display: \flex
  flex-direction: \column

flex = (flex-grow, flex-shring, flex-basis) -> {flex-grow, flex-shring, flex-basis}

const points-count = 100
const h = 100

EasingView = react.create-factory react.create-class do
  display-name: \EasingView
  should-component-update: -> not _.is-match @props, &0{name, easing}
  got-easing: (easing ? @props.easing) ->
    @values = [easing i, 0, h, points-count for i from 0 til points-count]

  component-will-mount: -> @got-easing!
  component-will-receive-props: ->
    @got-easing &0.easing if &0.easing != @props.easing
  component-did-mount: ->
    request-animation-frame @raf
    if @props.easing?
      insanimate.animate @demo-ref,
        * left: [0 100]
        * easing: @props.easing
          duration: 1000
          repeat: 1/0
          repeat-bounce: true

  raf: (ts) ->
    return unless @is-mounted!
    try
      return unless @values? and @animated-ref?

      const duration = 1200

      if @current-x? and @last-ts?
        @current-x += points-count * (ts - @last-ts) / duration
      else
        @current-x = 0
      @last-ts = ts
      
      while (x = Math.round @current-x) >= points-count => @current-x -= points-count
      y = @values[x]

      @animated-ref.style <<< do
        top: "#{scale y, 0, 100, 5, 95}px"
        left: "#{scale x, 0, 100, 5, 95}px"
    finally
      request-animation-frame @raf
      
   
  render: ->
    {name} = @props
    {values} = @

    DOM.div do
      style: h-flex-box! <<< do
        border: '1px solid #333'
        border-radius: \5px
        width: 'calc(50% - 4px)'
      DOM.div do
        style: v-flex-box!
        DOM.div null, name
        DOM.div do
          style:
            h-flex-box! <<< (flex 0, 0, \100px) <<< do
              width: \100px
              height: \100px
          DOM.svg do
            style: _.assign do
              flex 0, 0, \100%
              min-width: \100%
            view-box: "0 0 100 100"
            DOM.path do
              stroke: \black
              stroke-width: 2
              fill: \none
              d: ["M5,#{scale values[0], 0, 100, 5, 95}"].concat (values[1 til].map (y, x) -> "L#{scale x, 0, 100, 5, 95},#{scale y, 0, 100, 5, 95}") .join ''
          DOM.div do
            style: _.assign do
              flex 0, 0, \100%
              height: \100%
              min-width: \100%
              transform: 'translateX(-100%)'
            DOM.div do
              style:
                width: 6
                height: 6
                background-color: \#f00
                border-radius: \50%
                position: \relative
                transform: 'translateX(-50%) translateY(-50%)'
              ref: (@animated-ref) !~>
      DOM.div do
        class-name: 'demo-box'
        DOM.div do
          ref: (@demo-ref) !~>
          style:
            width: \20px
            height: \20px
            background-color: \#f00
            position: \relative

EasingsView = react.create-factory react.create-class do
  display-name: \EasingsView
  render: ->
    DOM.div do
      style:
        h-flex-box! <<< flex-wrap: \wrap
      (
        _.map Easing, (easing, name) ->
          EasingView {easing: easing, name, key: name}
      )[1 til]# 2]

FpsMeter = react.create-factory react.create-class do
  display-name: \FpsMeter
  get-initial-state: ->
    fps: 0

  raf: (ts) !->
    return unless @is-mounted!
    request-animation-frame @raf

    unless @post-ts?
      @post-ts = ts
      @counter = 0
    else if ts - @post-ts > 500
      @set-state fps: (@counter * 1000 / (ts - @post-ts))
      
      @post-ts = ts
      @counter = 0
    else
      ++@counter

  component-did-mount: ->
    request-animation-frame @raf
    
  render: ->
    DOM.div null, "#{math.round @state.fps, 1} fps"

render-svg-path = ([a, ...r]) ->
  ["M#{a.0} #{1 - a.1}"].concat (r.map -> "L#{it.0} #{1 - it.1}" ) .join ''








SpringGenCtx =
  springAccelerationForState: (o) ->
    (-o.tension * @x) - (o.friction * @v)
  
  springEvaluateStateWithDerivative: (o, dt, derivative) ->
    state =
      x: @x + derivative.dx * dt
      v: @v + derivative.dv * dt
      
    dx: @v
    dv: @springAccelerationForState.call state, o

  springIntegrateState: (o, dt) ->
    a =
      dx: @v
      dv: @springAccelerationForState o
    b = @springEvaluateStateWithDerivative o, dt * 0.5, a
    c = @springEvaluateStateWithDerivative o, dt * 0.5, b
    d = @springEvaluateStateWithDerivative o, dt, c
    @x += dt * 1.0 / 6.0 * (adx + 2.0 * (b.dx + c.dx) + d.dx)
    @v += dt * 1.0 / 6.0 * (adv + 2.0 * (b.dv + c.dv) + d.dv)

generateSpringRK4 = (tension, friction, duration) ->
  const tolerance = 1e-5
  const DT = 16 / 1000

  tension = (parseFloat tension) || 500
  friction = (parseFloat friction) || 20
  duration = duration || null

  have_duration = duration != null

  # Calculate the actual time it takes for this animation to complete with the provided conditions.
  if have_duration
    time_lapsed = generateSpringRK4 tension, friction # Run the simulation without a duration
    dt = time_lapsed / duration * DT # Compute the adjusted time delta
  else
    time_lapsed = 0
    dt = DT

  state = (Object.create SpringGenCtx) <<< do
    x: -1
    v: 0
  o = {tension, friction}
  path = [0]
  while true
    state.springIntegrateState o, dt
    path.push (1 + state.x)
    time_lapsed += 16
    break unless (Math.abs state.x) > tolerance and (Math.abs state.v) > tolerance

  # If duration is not defined, return the actual time required for completing this animation. Otherwise, return a closure that holds the
  # computed path and returns a snapshot of the position according to a given percentComplete.
  unless have_duration => time_lapsed else (percentComplete) ->
    path[ (percentComplete * (path.length - 1)) .|. 0 ]

BezierControl = react.create-factory react.create-class do
  display-name: \BezierControl
  component-did-mount: ->
    const padding = 0.1

    Hammer @root-ref .on 'pan', (e) !~>
      r = e.target.parent-node.get-bounding-client-rect!
      @props.did-moved [
        scale-to-r (e.center.x - r.left) / r.width, padding, 1 - padding
        scale-to-r (e.center.y - r.top) / r.height, padding, 1 - padding
      ]

  render: ->
    {c, r} = @props

    DOM.circle do
      key: &1
      ref: (@root-ref) !~>
      stroke: 'black'
      stroke-width: '.01px'
      fill: 'rgba(0,0,0,.001)'
      r: r
      cx: c.0, cy: c.1

BezierEditor = react.create-factory react.create-class do
  display-name: \BezierEditor
  get-initial-state: ->
    control-points: @control-points-changed fromJS [[0.25, 0.25], [0.5, 0.5], [0.75, 0.75]]

  control-points-changed: (cp ? @state.control-points) -> with cp
    console.log ..to-array!
    @lut = GetBezierApproximation do
      [[0,0]].concat ..to-JS! .concat [[1, 1]]
      30

  render: ->
    const padding = 0.1
    const ipadding = 1 - padding

    DOM.div do
      style:
        width: \200px
        height: \200px
        border: '1px solid #333'
      DOM.svg do
        width: \200px
        height: \200px
        view-box: '0, 0, 1, 1'
        DOM.path stroke: 'red', stroke-width: '.01px', fill: 'none', d: render-svg-path @lut?map (.map -> scale-from-r it, padding, ipadding)
        @state.control-points.map (c, idx) ~>
          c .= map (-> scale-from-r it, padding, ipadding) .to-array!
          c.1 = 1 - c.1
          const r = 0.02
          BezierControl {c, r, key: idx, did-moved: (.bind @, idx) (idx, v) ->
            v.1 = math.min (1 + padding), math.max (0 - padding), 1 - v.1
            v.0 = math.min (1 + padding), math.max (0 - padding), v.0
            @set-state control-points: @control-points-changed @state.control-points.set idx, List v }

App = react.create-class do
  display-name: \App
  
  render: ->
    DOM.div do

      null
      FpsMeter!
      BezierEditor!
      # DOM.div do
      #   on-click: ~> insanimate.animate @test-ref, {left: [100 0]}
      # DOM.div do
      #   ref: (@test-ref) !~>
      #   'TEST'
      # EasingsView!

window.onload = ->
  react-dom.render do
    react.create-element App, null
    document.get-element-by-id 'app'
