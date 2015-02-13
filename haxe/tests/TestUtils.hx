package;

class TestUtils
{
    public static function getTestDump():Dynamic
    {
        return {
            // bare values
            integer: 87,
            number: 1.423421e-3,
            string: "Hello, sweety!",
            bool: true,

            // arrays
            bare_array: [1, 2, 3],
            complex_array: [ {x: 10, y: 20}, {x: -5, y: -3}, null ],

            // maps
            bare_map: { a: "x", b: "x", c: "?"},
            complex_map: { uno: { x: false }, due: { x: true }, nothing: null },

            // complex values and nested model
            coords: { x: 5, y: -10.4 },
            inner: {
                integer: 194,
                string: "Inside level 2.",
                object: { x: 18, y: "string", z: [3,2,1] },
                coords: { x: -1, y: 2 }
            },

            // null-property
            nothing: null
        };
    }
}
